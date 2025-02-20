<organization-user-management>
    <div class="ui raised segment">
        <h1 class="ui dividing header">用户管理：</h1>
        <div class="ui right floated small green button" id="invite-user-button" onclick="{invite_users.bind(this)}">
            邀请用户
            <i class="user plus icon right"></i>
        </div>
        <table class="ui striped table">
            <thead>
                <tr>
                    <th>姓名</th>
                    <th>电子邮箱</th>
                    <th>加入时间</th>
                    <th>用户组</th>
                    <th>移除</th>
                </tr>
            </thead>
            <tbody>
                <tr each="{user in members}">
                    <td><a href="/profiles/user/{user.user.slug}/">{user.user.name}</a></td>
                    <td><a href="mailto:{user.user.email}">{user.user.email}</a></td>
                    <td>{user.date_joined}</td>
                    <td if="{user['group'] !== 'OWNER' && user['group'] !== 'INVITED'}">
                        <span>
                            <div class="ui inline dropdown">
                                <div class="text">{capitalize(user['group'])}
                                </div>
                                <i class="dropdown icon"></i>
                                <div class="menu">
                                    <div class="header">调整成员权限</div>
                                    <div class="item" data-member="{user.id}" data-value="MANAGER">管理员</div>
                                    <div class="item" data-member="{user.id}" data-value="PARTICIPANT">参与者</div>
                                    <div class="item" data-member="{user.id}" data-value="MEMBER">成员</div>
                                </div>
                            </div>
                            <div class="ui tiny inline loader"></div>
                        </span>
                    </td>
                    <td if="{user['group'] === 'OWNER' || user['group'] === 'INVITED'}">
                        <span class="text">{capitalize(user['group'])}</span>
                    </td>
                    <td if="{user['group'] !== 'OWNER'}"><button class="ui mini icon negative button"
                            onclick="{delete_member.bind(this, user.id, user.user.name)}">
                            <i class="x icon"></i>
                        </button></td>
                    <td if="{user['group'] === 'OWNER'}"></td>
                </tr>
            </tbody>
        </table>
        <div class="ui mini modal" ref="confirm_delete">
            <div class="header">请确认</div>
            <div class="content">
                确定要将 <strong>{pending_member_name}</strong> 从 <strong>{organization_name}</strong> 中移除吗？
            </div>
            <div class="actions">
                <div class="ui negative button">移除成员</div>
                <div class="ui ok button">取消</div>
            </div>
        </div>
        <div class="ui modal" ref="invite_users">
            <div class="ui header">邀请用户</div>
            <div class="content">
                <select class="ui fluid search multiple selection dropdown" multiple id="user_search">
                    <i class="dropdown icon"></i>
                    <div class="default text">选择协作者</div>
                    <div class="menu">
                    </div>
                </select>
            </div>
            <div class="actions">
                <div class="ui positive button">邀请用户</div>
                <div class="ui cancel button">取消</div>
            </div>
        </div>
    </div>

    <script>
        self_manage = this
        self_manage.members = organization.members
        self_manage.organization_name = organization.name
        self_manage.organization_id = organization.id
        self_manage.pending_member_name = ''

        self_manage.one("mount", function () {
            $('.ui.inline.dropdown').dropdown({
                onChange: function (value, text, choice) {
                    let loader = $(choice).parent().parent().parent().find('.loader')
                    loader.addClass('active')
                    let data = {
                        group: value,
                        membership: choice.data('member'),
                    }
                    CODALAB.api.update_user_group(data, self_manage.organization_id)
                        .done((data) => {
                            setTimeout(() => {
                                loader.removeClass('active')
                            }, 750)
                        })
                        .fail((response) => {
                            toastr.error('Failed to edit user')
                        })
                }
            })

            $(self_manage.refs.confirm_delete).modal({
                onDeny: function () {
                    CODALAB.api.delete_organization_member(self_manage.organization_id, { membership: self_manage.pending_member_id })
                        .done((data) => {
                            self_manage.members = self_manage.members.filter(user => user.id !== self_manage.pending_member_id)
                            self_manage.update()
                            self_manage.pending_member_id = undefined
                            self_manage.pending_member_name = undefined
                            return true
                        })
                        .fail((response) => {
                            toastr.error('Failed to remove member.')
                            self_manage.pending_member_id = undefined
                            self_manage.pending_member_name = undefined
                            return true
                        })
                },
            })

            $('#user_search').dropdown({
                apiSettings: {
                    url: `${URLS.API}user_lookup/?q={query}`,
                },
                clearable: true,
                preserveHTML: false,
                fields: {
                    title: 'name',
                    value: 'id',
                },
                cache: false,
                maxResults: 5,
            })
            $(self_manage.refs.invite_users).modal({
                onApprove: function () {
                    let users = $('#user_search').dropdown('get value')
                    CODALAB.api.invite_user_to_organization(self_manage.organization_id, { users: users })
                        .done((data) => {
                            toastr.success('邀请已发送')
                            location.reload()
                        })
                        .fail((response) => {
                            let errorMessage = "发生错误"; // 默认错误信息
                            if (response.responseJSON && response.responseJSON.message) {
                                errorMessage = response.responseJSON.message; // 解析后端返回的 message
                            }
                            toastr.error(errorMessage);
                            return true
                        })
                }
            })
        })

        self_manage.capitalize = (str) => {
            return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
        }

        self_manage.delete_member = (id, username) => {
            self_manage.pending_member_id = id
            self_manage.pending_member_name = username
            self_manage.update()
            $(self_manage.refs.confirm_delete)
                .modal('show')
        }

        self_manage.invite_users = () => {
            $(self_manage.refs.invite_users)
                .modal('show')
        }
    </script>
    <style>
        #invite-user-button {
            position: absolute;
            top: 14px;
            right: 14px;
        }
    </style>
</organization-user-management>