<profile-edit>
    <div class="ui raised segment">
    <h1>编辑个人资料</h1>
    <form class="ui form" id="user-form">
        <div class="field">
            <!-- Profile Photo -->
            <label>头像</label>
            <label show="{ photo }">
                更换为：<a href="{ photo }" target="_blank">{ photo_name }</a>
            </label>
            <div class="ui left action file input">
                <button class="ui icon button" type="button" onclick="document.getElementById('profile_phtoto').click()">
                    <i class="attach icon"></i>
                </button>
                <input id="profile_phtoto" type="file" ref="photo" accept="image/*">

                <!-- Just showing the file after it is uploaded -->
                <input value="{ logo_file_name }" readonly onclick="document.getElementById('profile_phtoto').click()">
            </div>
        </div>
        <div class="two fields">
            <div class="field" id="first_name">
                <label>名字</label>
                <input type="text" name="first_name" placeholder="名字">
            </div>
            <div class="field" id="last_name">
                <label>姓氏</label>
                <input type="text" name="last_name" placeholder="姓氏">
            </div>
        </div>
        <div class="two fields">
            <div class="field" id="display_name">
                <label>昵称</label>
                <input type="text" name="display_name" placeholder="昵称">
            </div>
            <div class="field" id="title">
                <label>职位</label>
                <input type="text" name="title" placeholder="职位"></div>
        </div>
        <div class="field" id="location">
            <label>地理位置</label>
            <input type="text" name="location" placeholder="地理位置"></div>
        <div class="field" id="email">
            <label>邮箱</label>
            <input disabled type="text" name="email" placeholder="邮箱">
        </div>
        <div class="two fields">
            <div class="field" id="personal_url">
                <label>个人网站</label>
                <input type="text" name="personal_url" placeholder="个人网站地址">
            </div>
            <div class="field" id="twitter_url">
                <label>Twitter地址</label>
                <input type="text" name="twitter_url" placeholder="Twitter地址">
            </div>
        </div>
        <div class="two fields">
            <div class="field" id="linkedin_url">
                <label>LinkedIn地址</label>
                <input type="text" name="linkedin_url" placeholder="LinkedIn地址">
            </div>
            <div class="field" id="github_url">
                <label>Github地址</label>
                <input type="text" name="github_url" placeholder="Github地址">
            </div>
        </div>
        <div class="field" id="biography">
            <label>简介</label>
            <textarea name="biography"></textarea>
        </div>
        <div class="ui error message"></div>
        <button type="button" class="ui primary button" onclick="{save.bind(this)}" ref="submit_button">提交</button>
    </form>
    </div>

    <script>
        self = this
        self.selected_user = selected_user
        self.photo = self.selected_user.photo
        delete self.selected_user.photo
        self.one("mount", function () {
            // Create http validation rule
            $.fn.form.settings.rules.test_http = function(param) {
                return /^(http|https):\/\/(.*)/.test(param)
            }
            // Prefill form with saved data
            $('#user-form').form('set values', {
                first_name:     selected_user.first_name,
                last_name:      selected_user.last_name,
                email:          selected_user.email,
                display_name:   selected_user.display_name,
                personal_url:   selected_user.personal_url,
                twitter_url:    selected_user.twitter_url,
                linkedin_url:   selected_user.linkedin_url,
                github_url:     selected_user.github_url,
                title:          selected_user.title,
                location:       selected_user.location,
                biography:      selected_user.biography,
                })
             $('#user-form').form({
                 keyboardShortcuts: false,
                 fields: {
                    email: {
                        identifier: 'email',
                        optional: true // Make the email field optional
                    },
                     personal_url: {
                         identifier: 'personal_url',
                         optional: true,
                         rules: [
                             {
                                 type: 'url',
                                 prompt: 'Please enter a valid url. Example: https://www.xyz.com'
                             },
                             {
                                 type: "test_http",
                                 prompt: '{name} must start with "http://" or "https://"'
                             }
                         ]
                     },
                     twitter_url: {
                         identifier: 'twitter_url',
                         optional: true,
                         rules: [
                             {
                                 type: 'url',
                                 prompt: 'Please enter a valid {name}. Example: https://twitter.com/BobRoss'
                             },
                             {
                                 type: "test_http",
                                 prompt: '{name} must start with "http://" or "https://"'
                             }
                         ]
                     },
                     linkedin_url: {
                         identifier: 'linkedin_url',
                         optional: true,
                         rules: [
                             {
                                 type: 'url',
                                 prompt: 'Please enter a valid {name}. Example: https://www.linkedin.com/in/john-doe'
                             },
                             {
                                 type: "test_http",
                                 prompt: '{name} must start with "http://" or "https://"'
                             }
                         ]
                     },
                     github_url: {
                         identifier: 'github_url',
                         optional: true,
                         rules: [
                             {
                                 type: 'url',
                                 prompt: 'Please enter a valid {name}. Example: https://github.com/john-doe'
                             },
                             {
                                 type: "test_http",
                                 prompt: '{name} must start with "http://" or "https://"'
                             }
                         ]
                     },
                 },
                 onSuccess: function () {
                     // get form values from user-form
                     const formValues = $('#user-form').form('get values')

                     // delete email from form values
                     delete formValues.email;

                     _.extend(self.selected_user, formValues)
                     CODALAB.api.update_user_details(self.selected_user.id, self.selected_user)
                         .done(data => {
                             toastr.success("Details Saved")
                             window.location.href = data
                         })
                         .fail(data => {
                             let errorsJSON = data.responseJSON
                             let errors = []
                             for(let key in errorsJSON){
                                 errors.push(self.camel_case_to_regular(key) + ' - ' + errorsJSON[key])
                                 $('#'+key).addClass('error')
                             }
                             $('#user-form').form('add errors', errors)
                             self.refs.submit_button.disabled = false
                         })
                     return false
                 },
                 onFailure: function (){
                     self.refs.submit_button.disabled = false
                 }
             })

            self.photo_name = typeof self.photo == 'undefined' || self.photo === null ? null : self.photo.replace(/\\/g, '/').replace(/.*\//, '')
            // Draw in logo filename as it's changed
            $(self.refs.photo).change(function () {
                self.logo_file_name = self.refs.photo.value.replace(/\\/g, '/').replace(/.*\//, '')
                self.update()
                getBase64(this.files[0]).then(function (data) {
                    self.selected_user['photo'] = JSON.stringify({file_name: self.logo_file_name, data: data})
                })
            })
            self.update()
        })

        self.camel_case_to_regular = (str) => {
            str = str.replaceAll('_', ' ')
            return str.replace(/(?:^|\s|["'([{])+\S/g, match => match.toUpperCase())
        }

        self.save = () => {
            self.refs.submit_button.disabled = true
            $('#user-form').form('validate form')
        }
    </script>
</profile-edit>
