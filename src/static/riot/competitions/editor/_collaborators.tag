<competition-collaborators>
    <div class="ui center aligned grid">
        <div class="row">
            <div class="fourteen wide column">
                <table class="ui padded table">
                    <thead>
                    <tr>
                        <th colspan="2">管理员</th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr>
                        <td>{created_by}</td>
                        <td class="right aligned">创建者</td>
                    </tr>
                    <tr each="{collab, index in collabs}">
                        <td>{collab.name || collab.username}</td>
                        <td class="right aligned">
                            <a class="icon-button"
                               onclick="{ remove_collaborator.bind(this, index, (collab.name || collab.username)) }">
                                <i class="red trash alternate outline icon"></i>
                            </a>
                        </td>
                    </tr>
                    </tbody>
                    <tfoot>
                    <tr>
                        <th colspan="2" class="right aligned">
                            <button class="ui tiny inverted green icon button" ref="modal_button">
                                <i class="add icon"></i> 添加管理员
                            </button>
                        </th>
                    </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>

    <div class="ui mini modal" ref="modal">
        <i class="close icon"></i>
        <div class="header">
            添加协作者
        </div>
        <div class="content">
            <div class="ui message error" if="{errors != null}">
                { errors }
            </div>
            <div class="ui form">
                <div class="field required">
                    <label>用户名</label>
                    <div class="ui fluid left icon labeled input search dataset" data-name="{file-field}">
                        <i class="search icon"></i>
                        <input type="text" class="prompt" ref="email">
                        <div class="results"></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="actions">
            <div class="ui button cancel" onclick="{ close_modal }">取消</div>
            <div class="ui button primary" onclick="{ add_collaborator }">添加</div>
        </div>
    </div>

    <script>
        var self = this
        self.collabs = []
        self.errors = null

        /*---------------------------------------------------------------------
            初始化
        ---------------------------------------------------------------------*/
        self.one("mount", function () {
            // 模态窗口
            $(self.refs.modal_button).click(function () {
                $(self.refs.modal).modal('show')
            })
            $('.ui.search', self.root)
                .search({
                    apiSettings: {
                        url: `${URLS.API}user_lookup/?q={query}`,
                    },
                    preserveHTML: false,
                    minCharacters: 2,
                    fields: {
                        title: 'name',
                        value: 'id',
                    },
                    cache: false,
                    maxResults: 5,
                    onSelect: (result, response) => {
                        self.new_collab = result
                    }
                })
        })

        /*---------------------------------------------------------------------
            方法
        ---------------------------------------------------------------------*/
        self.remove_collaborator = (index, name) => {
            if (confirm(`确定要移除协作者 ${name} 吗？`)) {
                self.collabs.splice(index,1)
                self.update()
            }
        }

        self.close_modal = () => {
            $(self.refs.modal).modal('hide')
            $(self.refs.email).val('')
            self.errors = null
        }

        self.add_collaborator = () => {
            if (self.new_collab) {
                if (self.new_collab.id === CODALAB.state.user.id) {
                    self.errors = "你不能将自己添加为协作者"
                } else if (self.new_collab.username === self.created_by) {
                    self.errors = "你不能将竞赛创建者添加为协作者"
                } else if (_.filter(self.collabs, collab => collab.id === self.new_collab.id).length === 0) {
                    self.collabs.push(self.new_collab)
                    self.new_collab = {}
                    self.close_modal()
                } else {
                    self.errors = `${self.new_collab.name} 已经是协作者`
                }
            } else {
                self.errors = '用户名不能为空'
            }
            self.update()
        }

        /*---------------------------------------------------------------------
            事件
        ---------------------------------------------------------------------*/
        CODALAB.events.on('competition_loaded', function (competition) {
            self.collabs = competition.collaborators
            self.created_by = competition.created_by
            self.update()
        })
    </script>

    <style type="text/stylus">
        .chevron, .icon-button
            cursor pointer
    </style>
</competition-collaborators>
