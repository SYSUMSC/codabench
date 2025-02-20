<organization-invite>
    <div class="ui raised segment">
        <h1 class="ui dividing header">组织邀请</h1>
        <div if="{state === 'loading'}" class="ui placeholder">
            <div class="paragraph">
                <div class="line"></div>
                <div class="line"></div>
                <div class="line"></div>
                <div class="line"></div>
                <div class="line"></div>
            </div>
        </div>
        <div if="{state === 'invite_valid'}">
            <div class="ui items">
                <div class="item">
                    <div class="content">
                        <div class="description">
                            您要接受来自 <strong>{invite_data.organization_name}</strong> 的邀请吗？
                        </div>
                        <div class="extra">邀请发送时间：{invite_data.date_joined}</div>
                        <div class="extra">
                            <div onclick="{accept_invite}" class="ui left floated positive button">
                                接受
                                <i class="right check icon"></i>
                            </div>
                            <div onclick="{reject_invite}" class="ui right floated negative button">
                                拒绝
                                <i class="right x icon"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div if="{state === 'invite_not_found'}">
            <div class="ui items">
                <div class="item">
                    <div class="content">
                        <div class="description">
                            <h3 class="header">未找到邀请</h3>
                        </div>
                        <div class="extra">
                            <a href="/"><button class="ui right floated button primary">返回首页</button></a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div if="{state === 'user_invite_mismatch'}">
            <div class="ui items">
                <div class="item">
                    <div class="content">
                        <div class="description">
                            <h3 class="header">此邀请不是发给当前登录用户的。</h3>
                            <div class="text">
                                请确保您登录了正确的账号，或请组织管理员重新发送邀请。
                            </div>
                        </div>
                        <div class="extra">
                            <a href="/"><button class="ui right floated button primary">返回首页</button></a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div if="{state === 'already_accepted'}">
            <div class="ui center aligned items">
                <div class="item">
                    <div class="content">
                        <div class="description">
                            <h3 class="header">邀请已被接受</h3>
                            <div class="text">
                                3秒后将跳转到竞赛页面。
                            </div>
                            <div class="ui active centered inline loader"></div>
                        </div>
                        <div class="extra">
                            <a href="/"><button class="ui right floated button primary">返回首页</button></a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div if="{state === 'unknown_error'}">
            <div class="ui items">
                <div class="item">
                    <div class="content">
                        <div class="description">
                            <h3 class="header">未知错误。</h3>
                            <div class="text">
                                无法验证此邀请。如果您认为这是一个错误，请联系管理员或在
                                <a href="https://github.com/codalab/competitions-v2">CODALAB GITHUB</a>
                                上提交问题。
                            </div>
                        </div>
                        <div class="extra">
                            <a href="/"><button class="ui right floated button primary">返回首页</button></a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script>
        self = this
        self.state = 'loading'
        self.queryString = window.location.search
        self.urlParams = new URLSearchParams(self.queryString)
        self.data = {token: self.urlParams.get('token')}

        self.one('mount', () => {
            CODALAB.api.validate_organization_invite(self.data)
                .done((data) => {
                    self.invite_data = data
                    self.state = 'invite_valid'
                    setTimeout(self.update, 250)
                })
                .fail((response) => {
                    if (response.status === 301){
                        self.state = 'already_accepted'
                        let org_url = response.responseJSON.redirect_url
                        if (org_url === undefined) {
                            org_url = '/'
                        }
                        setTimeout((redirect_url = org_url) => {
                            window.location.href = redirect_url
                        }, 3250)
                    }
                    else if (response.status === 400){
                        self.state = 'invite_not_found'
                    }
                    else if (response.status === 403){
                        self.state = 'user_invite_mismatch'
                    }
                    else {
                        self.state = 'unknown_error'
                    }
                    setTimeout(self.update, 250)
                })
        })

        self.accept_invite = () => {
            CODALAB.api.update_organization_invite(self.data, 'POST')
                .done((data) => {
                    if (data.redirect_url !== undefined) {
                        window.location.href = data.redirect_url
                    } else {
                        window.location.href = '/'
                    }

                })
                .fail((response) => {
                    toastr.error('抱歉！发生错误。请刷新页面后重试。')
                })
        }
        self.reject_invite = () => {
            data = {}
            CODALAB.api.update_organization_invite(self.data, 'DELETE')
                .done((data) => {
                    window.location.href = '/'
                })
                .fail((response) => {
                    toastr.error('抱歉！发生错误。请刷新页面后重试。')
                })
        }
    </script>
</organization-invite>
