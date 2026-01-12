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
# from itertools import islice
# for key, value in islice(manifest['nodes'].items(), 3):


class Lineage:
    def __init__(
        self,
        path: str = None,
        profiles_dir: str = "~/.dbt",
        target: Optional[str] = None
    ):
        if path is None:
            raise Exception("Path not specified.")
        f = open(os.path.join(path, "target", "manifest.json"))
        self.manifest = json.load(f)
        # 使用新的 DbtPostgresConnector 替代 FalDbt
        self.db_connector = DbtPostgresConnector(
            profiles_dir=profiles_dir,
            project_dir=path,
            target=target
        )
        self.output_dict = {}
        self._run_lineage()

    def _run_lineage(self) -> None:
        """
        Start the column lineage call
        :return: the output_dict object will be the final output with each model name being key
        """
        self.part_tables = self._get_part_tables()
        for key, value in self.manifest["nodes"].items():
            # 跳过 seed、test 和 analysis 节点（它们不适合血缘分析）
            node_type = key.split('.')[0]
            if node_type in ['seed', 'test', 'analysis', 'snapshot']:
                print(key, " skipped (node type: {})".format(node_type))
                continue

            table_name = value["schema"] + "." + value["name"]
            self.output_dict[key] = {}
            ret_sql = dbt_preprocess_sql(value)

            # 跳过没有 SQL 的节点
            if not ret_sql or ret_sql.strip() == "":
                print(key, " skipped (no SQL)")
                continue
            # 使用新的 db_connector 执行 SQL
            ret_result = self.db_connector.execute_sql(
                "EXPLAIN (VERBOSE TRUE, FORMAT JSON, COSTS FALSE) {}".format(ret_sql)
            )
            # PostgreSQL 的 EXPLAIN (FORMAT JSON) 返回的 QUERY PLAN 已经是 Python 列表
            # psycopg2 的 RealDictCursor 会自动解析 JSON 类型
            query_plan = ret_result.iloc[0]["QUERY PLAN"]
            if isinstance(query_plan, str):
                # 如果是字符串，需要解析 JSON
                plan = json.loads(query_plan[1:-1])
            elif isinstance(query_plan, list):
                # 如果已经是列表，直接使用第一个元素
                plan = query_plan[0]
            else:
                raise TypeError(f"Unexpected QUERY PLAN type: {type(query_plan)}")
            cols = dbt_find_column(table_name=table_name, engine=self.db_connector)
            col_lineage = ColumnLineage(
                plan=plan["Plan"],
                sql=ret_sql,
                columns=cols,
                conn=self.db_connector,
                part_tables=self.part_tables,
            )
            self.output_dict[key]["tables"] = col_lineage.table_list
            self.output_dict[key]["columns"] = col_lineage.column_dict
            self.output_dict[key]["table_name"] = table_name
            print(key, " completed")
        dbt_produce_json(self.output_dict, self.db_connector)

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
