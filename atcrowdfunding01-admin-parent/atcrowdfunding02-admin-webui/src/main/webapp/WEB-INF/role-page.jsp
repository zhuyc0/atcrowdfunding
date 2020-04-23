<%--
  Created by IntelliJ IDEA.
  User: zhuyc
  Date: 2020/4/23
  Time: 11:21
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@include file="/WEB-INF/include-header.jsp" %>
    <link rel="stylesheet" href="css/pagination.css"/>
    <script type="text/javascript" src="jquery/jquery.pagination.js"></script>
    <script type="text/javascript" src="crowd/crowd-role.js"></script>
    <script type="text/javascript">
        $(function () {
            // 1.为分页操作准备初始化数据
            window.pageNum = 1;
            window.pageSize = 10;
            window.keyword = "";

            // 2.调用执行分页的函数，显示分页效果
            generatePage();

            // 3.给查询按钮绑定单击响应函数
            $("#searchBtn").click(function () {

                // ①获取关键词数据赋值给对应的全局变量
                window.keyword = $("#keywordInput").val();

                // ②调用分页函数刷新页面
                generatePage();

            });

            // 4.点击新增按钮打开模态框
            $("#showAddModalBtn").click(function () {
                $("#addModal").modal("show");
            });

            // 5.给新增模态框中的保存按钮绑定单击响应函数
            $("#saveRoleBtn").click(function () {

                let element = $("#addModal input[name=roleName]");
                // ①获取用户在文本框中输入的角色名称
                // #addModal表示找到整个模态框
                // 空格表示在后代元素中继续查找
                // [name=roleName]表示匹配name属性等于roleName的元素
                let name = $.trim(element.val());

                // ②发送Ajax请求
                $.ajax({
                    "url": "role/save.json",
                    "type": "post",
                    "data": {name},
                    "dataType": "json",
                    "success": function (res) {
                        if (res.status === 200) {
                            layer.msg("操作成功！");
                            // 关闭模态框
                            $("#addModal").modal("hide");
                            // 清理模态框
                            element.val("");
                            // 将页码定位到第一页
                            window.pageNum = 1;
                            // 重新加载分页数据
                            generatePage();
                        } else {
                            layer.msg("操作失败！" + res.message);
                        }
                    },
                    "error": function (res) {
                        let data = res.responseJSON;
                        let msg = data ? (data.message || "系统错误") : res.statusText;
                        layer.msg(res.status + ", " + msg);
                    }
                });
            });

            // 6.给页面上的“铅笔”按钮绑定单击响应函数，目的是打开模态框
            // 传统的事件绑定方式只能在第一个页面有效，翻页后失效了
            // $(".pencilBtn").click(function(){
            // 	alert("aaaa...");
            // });

            // 使用jQuery对象的on()函数可以解决上面问题
            // ①首先找到所有“动态生成”的元素所附着的“静态”元素
            // ②on()函数的第一个参数是事件类型
            // ③on()函数的第二个参数是找到真正要绑定事件的元素的选择器
            // ③on()函数的第三个参数是事件的响应函数
            $("#rolePageBody").on("click",".pencilBtn",function(){
                // 打开模态框
                $("#editModal").modal("show");

                // 获取表格中当前行中的角色名称
                let roleName = $(this).parent().prev().text();

                // 获取当前角色的id
                // 依据是：var pencilBtn = "<button id='"+roleId+"' ……这段代码中我们把roleId设置到id属性了
                // 为了让执行更新的按钮能够获取到roleId的值，把它放在全局变量上
                window.roleId = this.id;

                // 使用roleName的值设置模态框中的文本框
                $("#editModal input[name=roleName]").val(roleName);
            });

            // 7.给更新模态框中的更新按钮绑定单击响应函数
            $("#updateRoleBtn").click(function(){

                // ①从文本框中获取新的角色名称
                let name = $("#editModal input[name=roleName]").val();

                // ②发送Ajax请求执行更新
                $.ajax({
                    "url":"role/modify.json",
                    "type":"post",
                    "data":{
                        "id":window.roleId,
                        name
                    },
                    "dataType":"json",
                    "success":function(res){
                        if(res.status === 200) {
                            layer.msg("操作成功！");
                            // ③关闭模态框
                            $("#editModal").modal("hide");
                            // 重新加载分页数据
                            generatePage();
                        }else {
                            layer.msg("操作失败！"+res.message);
                        }
                    },
                    "error":function(res){
                        let data = res.responseJSON;
                        let msg = data ? (data.message || "系统错误") : res.statusText;
                        layer.msg(res.status + ", " + msg);
                    }
                });
            });
        })
    </script>
</head>
<body>
<%@include file="/WEB-INF/include-nav.jsp" %>
<div class="container-fluid">
    <div class="row">
        <%@include file="/WEB-INF/include-sidebar.jsp" %>
        <div class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h3 class="panel-title">
                        <i class="glyphicon glyphicon-th"></i> 数据列表
                    </h3>
                </div>
                <div class="panel-body">
                    <form class="form-inline" role="form" style="float: left;">
                        <div class="form-group has-feedback">
                            <div class="input-group">
                                <div class="input-group-addon">查询条件</div>
                                <input id="keywordInput" class="form-control has-success" type="text"
                                       placeholder="请输入查询条件">
                            </div>
                        </div>
                        <button id="searchBtn" type="button" class="btn btn-warning">
                            <i class="glyphicon glyphicon-search"></i> 查询
                        </button>
                    </form>
                    <button id="batchRemoveBtn" type="button" class="btn btn-danger"
                            style="float: right; margin-left: 10px;">
                        <i class=" glyphicon glyphicon-remove"></i> 删除
                    </button>
                    <button
                            type="button"
                            id="showAddModalBtn" class="btn btn-primary"
                            style="float: right;">
                        <i class="glyphicon glyphicon-plus"></i> 新增
                    </button>
                    <br>
                    <hr style="clear: both;">
                    <div class="table-responsive">
                        <table class="table  table-bordered">
                            <thead>
                            <tr>
                                <th width="30">#</th>
                                <th width="30"><input id="summaryBox" type="checkbox"></th>
                                <th>名称</th>
                                <th width="100">操作</th>
                            </tr>
                            </thead>
                            <tbody id="rolePageBody"></tbody>
                            <tfoot>
                            <tr>
                                <td colspan="6" align="center">
                                    <div id="Pagination" class="pagination"><!-- 这里显示分页 --></div>
                                </td>
                            </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<%@include file="/WEB-INF/modal-role-add.jsp" %>
<%@include file="/WEB-INF/modal-role-edit.jsp" %>
<%@include file="/WEB-INF/modal-role-confirm.jsp" %>
</body>
</html>
