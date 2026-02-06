import os
import json
from typing import Optional

# 使用自定义的数据库连接器替代已废弃的 FalDbt
try:
    from db_connector import DbtPostgresConnector
except ImportError:
    from .db_connector import DbtPostgresConnector

try:
    from column_lineage import ColumnLineage
except ImportError:
    from .column_lineage import ColumnLineage

try:
    from utils import dbt_preprocess_sql, dbt_produce_json, dbt_find_column
except ImportError:
    from .utils import dbt_preprocess_sql, dbt_produce_json, dbt_find_column

try:
    from catalog_lineage import CatalogLineage
except ImportError:
    from .catalog_lineage import CatalogLineage

try:
    from lineage_fusion import LineageFusion
except ImportError:
    from .lineage_fusion import LineageFusion


class Lineage:
    def __init__(
        self,
        path: str = None,
        profiles_dir: str = "~/.dbt",
        target: Optional[str] = None,
        mode: str = "combine"  # 默认使用 combine 模式
    ):
        if path is None:
            raise Exception("Path not specified.")

        # 加载 manifest.json
        f = open(os.path.join(path, "target", "manifest.json"))
        self.manifest = json.load(f)

        # 加载 catalog.json
        self.catalog = None
        catalog_path = os.path.join(path, "target", "catalog.json")
        if os.path.exists(catalog_path):
            with open(catalog_path) as cf:
                self.catalog = json.load(cf)
            print(f"✓ 已加载 catalog.json")
        else:
            print(f"⚠ 警告: catalog.json 不存在，将仅使用 EXPLAIN 模式")

        # 使用新的 DbtPostgresConnector 替代 FalDbt
        self.db_connector = DbtPostgresConnector(
            profiles_dir=profiles_dir,
            project_dir=path,
            target=target
        )
        self.output_dict = {}
        self.mode = mode
        self._run_lineage()

    def _run_lineage(self) -> None:
        """
        使用 Combine 模式执行血缘分析
        :return: the output_dict object will be the final output with each model name being key
        """
        # 获取分区表映射
        self.part_tables = self._get_part_tables()

        for key, value in self.manifest["nodes"].items():
            # 跳过不适用的节点类型
            node_type = key.split('.')[0]
            if node_type in ['seed', 'test', 'analysis', 'snapshot']:
                print(key, " skipped (node type: {})".format(node_type))
                continue

            table_name = value["schema"] + "." + value["name"]
            print(f"\n{'='*60}")
            print(f"处理节点: {key}")
            print(f"表名: {table_name}")
            print(f"{'='*60}")

            self.output_dict[key] = {}

            # 步骤 1: 获取增强的列信息
            print(f"\n[步骤 1] 获取增强的列信息...")
            enhanced_columns = self._get_enhanced_columns(key, table_name)

            # 步骤 2: 执行 EXPLAIN 分析
            print(f"\n[步骤 2] 执行 EXPLAIN 分析...")
            explain_result = self._run_explain_analysis(key, value, table_name, enhanced_columns)

            # 步骤 3: 执行 Catalog 分析
            print(f"\n[步骤 3] 执行 Catalog 分析...")
            catalog_result = self._run_catalog_analysis(key, table_name)

            # 步骤 4: 融合结果
            print(f"\n[步骤 4] 融合分析结果...")
            fusion_engine = LineageFusion(
                explain_result=explain_result,
                catalog_result=catalog_result,
                enhanced_columns=enhanced_columns
            )
            fused_result = fusion_engine.fused_result

            # 步骤 5: 构建输出
            self.output_dict[key]["tables"] = fused_result["tables"]
            self.output_dict[key]["table_name"] = table_name
            self.output_dict[key]["table_metadata"] = fused_result["metadata"]["table_metadata"]
            
            # 获取基础的 column_metadata（从 catalog.json）
            column_metadata = fused_result["metadata"]["column_metadata"].copy()
            
            # 从 manifest.json 添加 tags 和 description
            self.output_dict[key]["tags"] = value.get("tags", [])
            self.output_dict[key]["description"] = value.get("description", "")

            # 获取列级别的描述 (从 manifest.json)
            manifest_columns = value.get("columns", {})
            column_descriptions = {}
            if manifest_columns:
                for col_name, col_info in manifest_columns.items():
                    column_descriptions[col_name] = col_info.get("description", "")
            
            # 获取增强的列元数据（从 fused_result["columns"]）
            enhanced_columns_metadata = fused_result.get("columns", {})
            
            # 步骤 6: 合并所有列元数据到 column_metadata
            for col_name in column_metadata.keys():
                # 1. 添加 description (从 manifest.json)
                if col_name in column_descriptions:
                    column_metadata[col_name]["description"] = column_descriptions[col_name]
                else:
                    column_metadata[col_name]["description"] = ""
                
                # 2. 合并 enhanced_columns_metadata 的字段
                if col_name in enhanced_columns_metadata:
                    enhanced_meta = enhanced_columns_metadata[col_name]
                    for field_name, field_value in enhanced_meta.items():
                        # 检查字段名是否冲突
                        if field_name in column_metadata[col_name]:
                            # 字段名冲突，重命名为 explain_${原字段}
                            new_field_name = f"explain_{field_name}"
                            column_metadata[col_name][new_field_name] = field_value
                        else:
                            # 无冲突，直接添加
                            column_metadata[col_name][field_name] = field_value
            
            # 设置最终的 column_metadata
            self.output_dict[key]["column_metadata"] = column_metadata
            
            # 保持向后兼容：保留 columns 字段（仅包含血缘列表）
            self.output_dict[key]["columns"] = {}
            for col_name, col_info in enhanced_columns_metadata.items():
                self.output_dict[key]["columns"][col_name] = col_info.get("sources", [""])

            print(f"\n✓ {key} 处理完成")
            print(f"  - 表依赖: {len(self.output_dict[key]['tables'])} 个")
            print(f"  - 列血缘: {len(self.output_dict[key]['columns'])} 个")

        # 生成最终输出
        print(f"\n{'='*60}")
        print(f"生成最终输出...")
        print(f"{'='*60}")
        dbt_produce_json(self.output_dict, self.db_connector)

    def _get_enhanced_columns(self, node_id: str, table_name: str) -> dict:
        """
        获取增强的列信息，同时从 catalog.json 和数据库获取

        :param node_id: 节点唯一标识 (如 "model.qrs.dim_analysts")
        :param table_name: 表名 (如 "public.dim_analysts")
        :return: {
            "column_names": ["analyst_id", "analyst_code", ...],
            "catalog_columns": {...},
            "db_columns": [...],
            "is_consistent": true,
            "conflicts": []
        }
        """
        result = {
            "column_names": [],
            "catalog_columns": {},
            "db_columns": [],
            "is_consistent": True,
            "conflicts": []
        }

        # 1. 从 catalog.json 获取列信息
        if self.catalog and node_id in self.catalog.get("nodes", {}):
            catalog_node = self.catalog["nodes"][node_id]
            catalog_columns = catalog_node.get("columns", {})
            result["catalog_columns"] = catalog_columns
            result["column_names"] = list(catalog_columns.keys())
            print(f"  ✓ 从 catalog.json 获取 {len(catalog_columns)} 个列")
        else:
            print(f"  ⚠ catalog.json 中无节点 {node_id}")

        # 2. 从数据库获取列信息
        try:
            db_columns = dbt_find_column(table_name=table_name, engine=self.db_connector)
            result["db_columns"] = db_columns
            print(f"  ✓ 从数据库获取 {len(db_columns)} 个列")
        except Exception as e:
            print(f"  ✗ 数据库查询失败: {e}")
            result["db_columns"] = []

        # 3. 验证一致性
        if result["catalog_columns"] and result["db_columns"]:
            catalog_cols = set(result["catalog_columns"].keys())
            db_cols = set(result["db_columns"])

            if catalog_cols != db_cols:
                result["is_consistent"] = False

                # 识别冲突
                missing_in_catalog = db_cols - catalog_cols
                missing_in_db = catalog_cols - db_cols

                if missing_in_catalog:
                    result["conflicts"].append({
                        "type": "missing_in_catalog",
                        "columns": list(missing_in_catalog)
                    })
                    print(f"  ⚠ 冲突: catalog.json 缺少列 {missing_in_catalog}")

                if missing_in_db:
                    result["conflicts"].append({
                        "type": "missing_in_db",
                        "columns": list(missing_in_db)
                    })
                    print(f"  ⚠ 冲突: 数据库缺少列 {missing_in_db}")
            else:
                print(f"  ✓ catalog.json 和数据库列信息一致")

        # 4. 确定最终的列名列表 (优先使用 catalog.json)
        if result["catalog_columns"]:
            result["column_names"] = list(result["catalog_columns"].keys())
        elif result["db_columns"]:
            result["column_names"] = result["db_columns"]
        else:
            result["column_names"] = []

        return result

    def _run_explain_analysis(
        self,
        key: str,
        value: dict,
        table_name: str,
        enhanced_columns: dict
    ) -> dict:
        """执行 EXPLAIN 分析"""
        ret_sql = dbt_preprocess_sql(value)

        # 跳过没有 SQL 的节点
        if not ret_sql or ret_sql.strip() == "":
            print(f"  ⚠ 跳过 (无 SQL)")
            return {"tables": [], "columns": {}, "metadata": {}}

        # 执行 EXPLAIN
        ret_result = self.db_connector.execute_sql(
            "EXPLAIN (VERBOSE TRUE, FORMAT JSON, COSTS FALSE) {}".format(ret_sql)
        )
        query_plan = ret_result.iloc[0]["QUERY PLAN"]
        if isinstance(query_plan, str):
            plan = json.loads(query_plan[1:-1])
        elif isinstance(query_plan, list):
            plan = query_plan[0]
        else:
            raise TypeError(f"Unexpected QUERY PLAN type: {type(query_plan)}")

        # 使用增强的列信息
        cols = enhanced_columns["column_names"]

        # 解析血缘
        col_lineage = ColumnLineage(
            plan=plan["Plan"],
            sql=ret_sql,
            columns=cols,
            conn=self.db_connector,
            part_tables=self.part_tables,
        )

        result = {
            "tables": col_lineage.table_list,
            "columns": col_lineage.column_dict,
            "metadata": {
                "mode": "explain",
                "query_plan": plan
            }
        }

        print(f"  ✓ EXPLAIN 分析完成")
        print(f"    - 表依赖: {len(result['tables'])} 个")
        print(f"    - 列血缘: {len(result['columns'])} 个")

        return result

    def _run_catalog_analysis(self, key: str, table_name: str) -> dict:
        """执行 Catalog 分析"""
        if not self.catalog:
            print(f"  ⚠ 跳过 (无 catalog.json)")
            return {"tables": [], "columns": {}, "metadata": {}}

        catalog_lineage = CatalogLineage(
            manifest=self.manifest,
            catalog=self.catalog,
            node_id=key
        )

        result = {
            "tables": catalog_lineage.table_list,
            "columns": catalog_lineage.column_dict,
            "metadata": catalog_lineage.metadata
        }

        print(f"  ✓ Catalog 分析完成")
        print(f"    - 表依赖: {len(result['tables'])} 个")
        print(f"    - 列血缘: {len(result['columns'])} 个")

        return result

    def _get_part_tables(self) -> dict:
        """
        Find the partitioned table and their parents, so that the final output would only show the parent table name
        :return: a dict with child being key and parent being the value
        """
        parent_result = self.db_connector.execute_sql(
            """SELECT
                    concat_ws('.', nmsp_parent.nspname, parent.relname) AS parent,
                    concat_ws('.', nmsp_child.nspname, child.relname) AS child
                FROM pg_inherits
                    JOIN pg_class parent            ON pg_inherits.inhparent = parent.oid
                    JOIN pg_class child             ON pg_inherits.inhrelid   = child.oid
                    JOIN pg_namespace nmsp_parent   ON nmsp_parent.oid  = parent.relnamespace
                    JOIN pg_namespace nmsp_child    ON nmsp_child.oid   = child.relnamespace"""
        )
        return dict(zip(parent_result.child, parent_result.parent))

    def close(self) -> None:
        """关闭数据库连接"""
        if hasattr(self, 'db_connector') and self.db_connector:
            self.db_connector.close()

    def __del__(self):
        """析构函数，确保连接被关闭"""
        self.close()


if __name__ == "__main__":
    # 示例用法
    lineage_output = Lineage(path=".", profiles_dir="~/.dbt")
