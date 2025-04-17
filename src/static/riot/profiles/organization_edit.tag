<organization-edit>
    <div class="ui raised segment">
    <h1 class="ui dividing header">编辑队伍：</h1>
    <form class="ui form" id="organization-form">
        <div class="field">
            <label>队伍照片</label>
            <label show="{ original_org_photo }">
                已上传照片: <a href="{ original_org_photo }" target="_blank">{ original_org_photo_name }</a>
            </label>
            <div class="ui left action file input">
                <button class="ui icon button" type="button" onclick="document.getElementById('profile_phtoto').click()">
                    <i class="attach icon"></i>
                </button>
                <input id="profile_phtoto" type="file" ref="photo" accept="image/*">

                <!-- 仅显示上传后的文件名 -->
                <input value="{ logo_file_name }" readonly onclick="document.getElementById('profile_phtoto').click()">
            </div>
        </div>
        <div class="two fields">
            <div class="required field" id="name">
                <label>队伍名称</label>
                <input type="text" name="name" placeholder="名称">
            </div>
            <div class="required field" id="email">
                <label>队伍邮箱</label>
                <input type="text" name="email" placeholder="email@organization.com">
            </div>
        </div>
        <div class="ui error message"></div>
        <div class="ui primary button" onclick="{save.bind(this)}" id="submit_button">提交</div>
        <a href="{self.organization.url}">
            <button type="button" class="ui button">返回队伍页面</button>
        </a>
    </form>
    </div>
    <script>
        self = this
        // Make sure organization is defined to prevent errors
        if (typeof organization === 'undefined') {
            organization = { name: '', email: '', location: '', description: '', website_url: '', linkedin_url: '', twitter_url: '', github_url: '', has_submissions: false }
        }

        // Create a deep copy of the organization object to avoid modifying the original
        self.organization = JSON.parse(JSON.stringify(organization))

        // Handle photo separately since it might be undefined
        if (organization.photo) {
            self.original_org_photo_name = organization.photo.replace(/\\/g, '/').replace(/.*\//, '')
            self.original_org_photo = organization.photo
        } else {
            self.original_org_photo_name = ''
            self.original_org_photo = null
        }


        self.one("mount", function () {
            self.submit_button = $('#submit_button')
            $.fn.form.settings.rules.test_http = function(param) {
                return /^(http|https):\/\/(.*)/.test(param)
            }

            $('#organization-form').form('set values', {
                name: self.organization.name,
                email: self.organization.email,
                location: self.organization.location,
                description: self.organization.description,
                website_url: self.organization.website_url,
                linkedin_url: self.organization.linkedin_url,
                twitter_url: self.organization.twitter_url,
                github_url: self.organization.github_url,
            })

            $('#organization-form').form({
                keyboardShortcuts: false,
                fields: {
                    name: {
                        identifier: 'name',
                        optional: false,
                        rules: [{
                            type: 'empty'
                        }]
                    },
                    email: {
                        identifier: 'email',
                        optional: false,
                        rules: [{
                            type: 'email',
                            prompt: '请输入有效的{name}'
                        }]
                    },
                    website_url: {
                        identifier: 'website_url',
                        optional: true,
                        rules: [
                            {
                                type: 'url',
                                prompt: '请输入有效的{name}。示例: https://organization.com'
                            },
                            {
                                type: 'test_http',
                                prompt: '{name}必须以"http://"或"https://"开头'
                            }
                        ]
                    },
                    twitter_url: {
                        identifier: 'twitter_url',
                        optional: true,
                        rules: [
                            {
                                type: 'url',
                                prompt: '请输入有效的{name}。示例: https://organization.com'
                            },
                            {
                                type: 'test_http',
                                prompt: '{name}必须以"http://"或"https://"开头'
                            }
                        ]
                    },
                    linkedin_url: {
                        identifier: 'linkedin_url',
                        optional: true,
                        rules: [
                            {
                                type: 'url',
                                prompt: '请输入有效的{name}。示例: https://www.linkedin.com/company/organization'
                            },
                            {
                                type: 'test_http',
                                prompt: '{name}必须以"http://"或"https://"开头'
                            }
                        ]
                    },
                    github_url: {
                        identifier: 'github_url',
                        optional: true,
                        rules: [
                            {
                                type: 'url',
                                prompt: '请输入有效的{name}。示例: https://github.com/organization'
                            },
                            {
                                type: 'test_http',
                                prompt: '{name}必须以"http://"或"https://"开头'
                            }
                        ]
                    },
                },
                onSuccess: function () {
                    data = $('#organization-form').form('get values')
                    data.photo = self.org_photo
                    CODALAB.api.update_organization(data, self.organization.id)
                        .done(data => {
                            toastr.success("队伍信息已保存")
                            self.submit_button.prop('disabled', false)
                        })
                        .fail(data => {
                            let errorsJSON = data.responseJSON
                            let errors = []
                            for(let key in errorsJSON){
                                errors.push(self.camel_case_to_regular(key) + ' - ' + errorsJSON[key])
                                $('#'+key).addClass('error')
                            }
                            $('#organization-form').form('add errors', errors)
                            self.submit_button.prop('disabled', false)
                        })
                    return false
                },
                onFailure: function () {
                    self.submit_button.prop('disabled', false)
                }
            })

            // Draw in logo filename as it's changed
            $(self.refs.photo).change(function () {
                self.logo_file_name = self.refs.photo.value.replace(/\\/g, '/').replace(/.*\//, '')
                self.update()
                getBase64(this.files[0]).then(function (data) {
                    self.org_photo = JSON.stringify({file_name: self.logo_file_name, data: data})
                })
            })
        })

        self.camel_case_to_regular = (str) => {
            str = str.replaceAll('_', ' ')
            return str.replace(/(?:^|\s|["'([{])+\S/g, match => match.toUpperCase())
        }

        self.save = () => {
            self.submit_button.prop('disabled', true)
            $('#organization-form').form('validate form')
        }
    </script>
</organization-edit>
