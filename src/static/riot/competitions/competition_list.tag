<competition-list>
    <div class="ui vertical stripe segment">
        <div class="ui middle aligned stackable grid container centered">
            <div class="row">
                <div class="fourteen wide column">
                    <div class="ui fluid secondary pointing tabular menu">
                        <a class="active item" data-tab="participating">我参与的题目</a>
                        <a class="item" data-tab="running">我正在运行的题目</a>
                        <div class="right menu">
                            <div class="item">
                                <help_button href="https://github.com/codalab/competitions-v2/wiki/Competition-Management-&-List"></help_button>
                            </div>
                        </div>
                    </div>
                    <div class="ui active tab" data-tab="participating">
                        <table class="ui celled compact table">
                            <thead>
                            <tr>
                                <th>名称</th>
                                <th width="125px">上传时间</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr each="{ competition in participating_competitions }" style="height: 42px;">
                                <td><a href="{ URLS.COMPETITION_DETAIL(competition.id) }">{ competition.title }</a></td>
                                <td>{ timeSince(Date.parse(competition.created_when)) } 之前</td>
                            </tr>
                            </tbody>
                            <tfoot>
                            </tfoot>
                        </table>
                    </div>
                    <div class="ui tab" data-tab="running">
                        <table class="ui celled compact table participation">
                            <thead>
                            <tr>
                                <th>名称</th>
                                <th width="100">类型</th>
                                <th width="125">上传时间</th>
                                <th width="50px">发布</th>
                                <th width="50px">编辑</th>
                                <th width="50px">删除</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr each="{ competition in running_competitions }" no-reorder>
                                <td><a href="{ URLS.COMPETITION_DETAIL(competition.id) }">{ competition.title }</a></td>
                                <td class="center aligned">{ competition.competition_type }</td>
                                <td>{ timeSince(Date.parse(competition.created_when)) } 之前</td>
                                <td class="center aligned">
                                    <!--<button class="mini ui button green icon" show="{ !competition.published }" onclick="{ publish_competition.bind(this, competition) }">
                                        <i class="icon external alternate"></i>
                                    </button>-->
                                    <button class="mini ui button published icon { grey: !competition.published, green: competition.published }"
                                            onclick="{ toggle_competition_publish.bind(this, competition) }">
                                        <i class="icon file"></i>
                                    </button>
                                </td>
                                <td class="center aligned">
                                    <a href="{ URLS.COMPETITION_EDIT(competition.id) }"
                                       class="mini ui button blue icon">
                                        <i class="icon edit"></i>
                                    </a>
                                </td>
                                <td class="center aligned">
                                    <button class="mini ui button red icon"
                                            onclick="{ delete_competition.bind(this, competition) }">
                                        <i class="icon delete"></i>
                                    </button>
                                </td>
                            </tr>
                            </tbody>
                            <tfoot>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script>
        var self = this

        self.one("mount", function () {
            self.update_competitions()
            $('.tabular.menu .item').tab();
        })

        self.update_competitions = function () {
            self.get_participating_in_competitions()
            self.get_running_competitions()
        }

        // 封装获取赛题数据的方法
        self.get_competitions_wrapper = function (query_params) {
            return CODALAB.api.get_competitions(query_params)
                .fail(function (response) {
                    toastr.error("无法加载赛题列表")
                })
        }

        // 获取用户参与的赛题
        self.get_participating_in_competitions = function () {
            self.get_competitions_wrapper({participating_in: true})
                .done(function (data) {
                    self.participating_competitions = data
                    self.update()
                })
        }

        // 获取用户运行的赛题
        self.get_running_competitions = function () {
            self.get_competitions_wrapper({
                mine: true,
                type: 'any',
            })
                .done(function (data) {
                    self.running_competitions = data
                    self.update()
                })
        }

        // 删除赛题
        self.delete_competition = function (competition) {
            if (confirm("你确定要删除 '" + competition.title + "' 吗？")) {
                CODALAB.api.delete_competition(competition.id)
                    .done(function () {
                        self.update_competitions()
                        toastr.success("赛题删除成功")
                    })
                    .fail(function () {
                        toastr.error("赛题删除失败")
                    })
            }
        }

        // 切换赛题的发布状态
        self.toggle_competition_publish = function (competition) {
            CODALAB.api.toggle_competition_publish(competition.id)
                .done(function (data) {
                    var published_state = data.published ? "已发布" : "未发布"
                    toastr.success(`赛题已成功${published_state}`)
                    self.get_running_competitions()
                })
        }

    </script>
    <style type="text/stylus">
        .table.participation
            .published.icon.grey
                opacity 0.65
                transition 0.25s all ease-in-out

                &:hover
                    background-color #21ba45

    </style>
</competition-list>
