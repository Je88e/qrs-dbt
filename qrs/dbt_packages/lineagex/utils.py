import os
import re
import json
from typing import Tuple, List, Any


def _remove_comments(str1: str = "") -> str:
    """
    Remove comments/excessive spaces/"create table as"/"create view as" from the sql file
    :param str1: the original sql
    :return: the parsed sql
    """
    # remove the /* */ comments
    q = re.sub(r"/\*[^*]*\*+(?:[^*/][^*]*\*+)*/", "", str1)
    # remove whole line -- and # comments
    lines = [line for line in q.splitlines() if not re.match(r"^\s*(--|#)", line)]
    # remove trailing -- and # comments
    q = " ".join([re.split("--|#", line)[0] for line in lines])
    # replace all spaces around commas
    q = re.sub(r"\s*,\s*", ",", q)
    # replace all multiple spaces to one space
    str1 = re.sub(r"\s\s+", " ", q)
    str1 = str1.replace("\n", " ").strip()
    return str1


def dbt_preprocess_sql(node: dict = None) -> str:
    """
    Process the sql, remove database name in the clause/datetime_add/datetime_sub adding quotes
    :param node: the node containing the original sql, file: file name for the sql
    :return: None
    """
    if node is None:
        return ""

    # 某些节点类型（如 seed）没有 compiled_code
    if "compiled_code" not in node:
        return ""

    org_sql = node["compiled_code"]
    ret_sql = _remove_comments(str1=org_sql)
    ret_sql = ret_sql.replace("`", "")
    # remove any database names in the query
    schema = node["schema"]
    #     for i in schemas:
    #         ret_sql = re.sub("[^ (,]*(\.{}\.)".format(i), "{}.".format(i), ret_sql)
    ret_sql = re.sub(r"[^ (,]*(\.{}\.)".format(schema), r"{}.".format(schema), ret_sql)
    ret_sql = re.sub(
        r"DATETIME_DIFF\((.+?),\s?(.+?),\s?(DAY|MINUTE|SECOND|HOUR|YEAR)\)",
        r"DATETIME_DIFF(\1, \2, '\3'::TEXT)",
        ret_sql,
    )
    ret_sql = re.sub("datetime_add", "DATETIME_ADD", ret_sql, flags=re.IGNORECASE)
    ret_sql = re.sub("datetime_sub", "DATETIME_SUB", ret_sql, flags=re.IGNORECASE)
    # DATETIME_ADD '' value
    dateime_groups = re.findall(
        r"DATETIME_ADD\(\s?(.+?),\s?INTERVAL\s?(.+?)\s?(DAY|MINUTE|SECOND|HOUR|YEAR)\)",
        ret_sql,
    )
    if dateime_groups:
        for i in dateime_groups:
            if not i[1].startswith("'") and not i[1].endswith("'"):
                ret_sql = ret_sql.replace(
                    "DATETIME_ADD({},INTERVAL {} {})".format(i[0], i[1], i[2]),
                    "DATETIME_ADD({},INTERVAL '{}' {})".format(i[0], i[1], i[2]),
                )
            else:
                continue
    # DATETIME_SUB '' value
    dateime_sub_groups = re.findall(
        r"DATETIME_SUB\(\s?(.+?),\s?INTERVAL\s?(.+?)\s?(DAY|MINUTE|SECOND|HOUR|YEAR)\)",
        ret_sql,
    )
    if dateime_sub_groups:
        for i in dateime_sub_groups:
            if not i[1].startswith("'") and not i[1].endswith("'"):
                ret_sql = ret_sql.replace(
                    "DATETIME_SUB({},INTERVAL {} {})".format(i[0], i[1], i[2]),
                    "DATETIME_SUB({},INTERVAL '{}' {})".format(i[0], i[1], i[2]),
                )
            else:
                continue
    return ret_sql


def dbt_find_column(table_name: str = "", engine: Any = None) -> List:
    """
    Find the columns for the base table in the database
    :param engine: the connection engine (DbtPostgresConnector or compatible)
    :param table_name: the base table name
    :return: the list of columns in the base table
    """
    cols_result = engine.execute_sql(
        """SELECT attname AS col
    FROM   pg_attribute
    WHERE  attrelid = '{}'::regclass  -- table name optionally schema-qualified
    AND    attnum > 0
    AND    NOT attisdropped
    ORDER  BY attnum;
     ;""".format(
            table_name
        )
    )
    return list(cols_result["col"])


def dbt_produce_json(output_dict: dict = None, engine: Any = None) -> dict:
    """
    生成血缘 JSON 输出（支持增强格式）

    :param output_dict: 血缘分析结果
    :param engine: 数据库连接
    :return: 血缘字典
    """
    table_to_model_dict = {}
    for key, val in output_dict.items():
        table_to_model_dict[val["table_name"]] = key

    dep_dict = {}
    for key, val in output_dict.items():
        if key not in dep_dict.keys():
            dep_dict[key] = {}
            dep_dict[key]["upstream_tables"] = val["tables"]
        else:
            dep_dict[key]["upstream_tables"] = val["tables"]
        for i in val["tables"]:
            key_name = table_to_model_dict.get(i, i)
            if key_name not in dep_dict.keys():
                dep_dict[key_name] = {}
                dep_dict[key_name]["downstream_tables"] = [key]
            else:
                if "downstream_tables" not in dep_dict[key_name].keys():
                    dep_dict[key_name]["downstream_tables"] = [key]
                else:
                    dep_dict[key_name]["downstream_tables"].append(key)
    base_table_dict = {}
    for key, val in dep_dict.items():
        if "upstream_tables" not in list(val.keys()):
            val["upstream_tables"] = []
        if "downstream_tables" not in list(val.keys()):
            val["downstream_tables"] = []
        if key in list(output_dict.keys()):
            val["is_model"] = True
        else:
            base_table_dict[key] = {}
            base_table_dict[key]["tables"] = [""]
            base_table_dict[key]["columns"] = {}
            cols = dbt_find_column(key, engine)
            for i in cols:
                base_table_dict[key]["columns"][i] = [""]
            base_table_dict[key]["table_name"] = str(key)
            val["is_model"] = False

    # 合并 output_dict 和 dep_dict 的信息
    base_table_dict.update(output_dict)

    # 将 dep_dict 中的 upstream_tables, downstream_tables, is_model 添加到 base_table_dict
    for key, val in dep_dict.items():
        if key in base_table_dict:
            base_table_dict[key]["upstream_tables"] = val.get("upstream_tables", [])
            base_table_dict[key]["downstream_tables"] = val.get("downstream_tables", [])
            base_table_dict[key]["is_model"] = val.get("is_model", False)

    # 生成增强的输出
    enhanced_output = _enhance_output(base_table_dict, engine)

    # 确保输出目录存在
    os.makedirs("output", exist_ok=True)

    with open("output/output.json", "w", encoding="utf-8") as outfile:
        json.dump(enhanced_output, outfile, indent=2, ensure_ascii=False)

    print(f"\n✓ 血缘信息已保存到 output/output.json")

    # 生成统计报告
    _generate_summary_report(enhanced_output)

    # 生成 HTML
    _produce_html(output_json=str(enhanced_output).replace("'", '"'))

    return enhanced_output


def _enhance_output(output_dict: dict, engine: Any = None) -> dict:
    """
    增强输出字典，将新格式转换为兼容格式

    为了保持向后兼容，需要将增强的列血缘信息转换为旧的列表格式
    """
    enhanced = {}

    for key, val in output_dict.items():
        enhanced[key] = {
            "tables": val.get("tables", []),
            "table_name": val.get("table_name", ""),
            "upstream_tables": val.get("upstream_tables", []),
            "downstream_tables": val.get("downstream_tables", []),
            "is_model": val.get("is_model", False)
        }

        # 处理列血缘：如果列信息是增强格式（字典），需要转换为列表格式
        columns = val.get("columns", {})
        if columns:
            # 检查是否是增强格式
            first_col = next(iter(columns.values()), None)
            if isinstance(first_col, dict):
                # 是增强格式，需要转换
                enhanced[key]["columns"] = {}
                for col_name, col_info in columns.items():
                    if isinstance(col_info, dict):
                        # 从增强格式提取 sources
                        enhanced[key]["columns"][col_name] = col_info.get("sources", [""])
                        # 保存增强信息到元数据字段（供支持新格式的解析器使用）
                        if "enhanced_columns_metadata" not in enhanced[key]:
                            enhanced[key]["enhanced_columns_metadata"] = {}
                        enhanced[key]["enhanced_columns_metadata"][col_name] = col_info
                    else:
                        # 已经是列表格式
                        enhanced[key]["columns"][col_name] = col_info
            else:
                # 已经是旧格式
                enhanced[key]["columns"] = columns

        # 添加表元数据字段（如果存在）
        if "table_metadata" in val:
            enhanced[key]["table_metadata"] = val["table_metadata"]

        if "column_metadata" in val:
            enhanced[key]["column_metadata"] = val["column_metadata"]

        # 添加 manifest.json 元数据字段
        if "tags" in val:
            enhanced[key]["tags"] = val["tags"]

        if "description" in val:
            enhanced[key]["description"] = val["description"]

        if "column_descriptions" in val:
            enhanced[key]["column_descriptions"] = val["column_descriptions"]

    return enhanced


def _generate_summary_report(output_dict: dict):
    """生成统计报告"""
    total_nodes = len(output_dict)
    model_nodes = sum(1 for v in output_dict.values() if v.get("is_model", False))
    base_nodes = total_nodes - model_nodes

    # 统计有描述信息的节点数
    nodes_with_description = sum(
        1 for v in output_dict.values() if v.get("description")
    )

    # 统计有 tags 的节点数
    nodes_with_tags = sum(
        1 for v in output_dict.values() if v.get("tags")
    )

    total_columns = sum(
        len(v.get("columns", {}))
        for v in output_dict.values()
    )

    print(f"\n{'='*60}")
    print(f"血缘分析统计报告")
    print(f"{'='*60}")
    print(f"总节点数: {total_nodes}")
    print(f"  - 模型节点: {model_nodes}")
    print(f"  - 基础表: {base_nodes}")
    print(f"总列数: {total_columns}")
    print(f"有描述的节点: {nodes_with_description}")
    print(f"有标签的节点: {nodes_with_tags}")
    print(f"{'='*60}")


def _produce_html(output_json: str = ""):
    # Creating the HTML file
    file_html = open("output/index.html", "w", encoding="utf-8")
    # Adding the input data to the HTML file
    file_html.write('''<!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="X-UA-Compatible" content="ie=edge">
    </head>
    <body>
      <script>
        window.inlineSource = `{}`;
      </script>
      <div id="main"></div>
    <script type="text/javascript" src="vendor.js"></script><script type="text/javascript" src="app.js"></script></body>
    </html>'''.format(output_json))
    # Saving the data into the HTML file
    file_html.close()


if __name__ == "__main__":
    pass
