<profile-account>
    <!-- Delete account section -->
    <div id="delete-account">
        <h2 class="title danger">删除账号</h2>
        <div class="ui divider"></div>
        <!-- Deleting your account is permanent and cannot be undone. All your personal data, settings, and content will be permanently erased, and you will lose access to all services linked to your account. Please make sure to back up any important information before proceeding. -->
        <p><b>警告：</b>您的账号将被永久删除，无法撤销。所有个人数据、设置和内容将被永久删除，您将无法访问与您的帐户关联的所有服务。在继续之前，请务必备份任何重要信息。</p>
         <!-- Permanently delete my account -->
        <button type="button" class="ui button delete-button" ref="delete_button" onclick="{show_modal.bind(this, '.delete-account.modal')}">永久删除我的账号</button>
    </div>

    <!-- Delete account modal -->
    <div class="ui delete-account modal tiny" ref="delete_account_modal">
        <div class="header">您确定要删除吗？</div>

        <div class="ui bottom attached negative message">
            <i class="exclamation triangle icon"></i>
            <!-- This is extremely important. -->
             请务必谨慎操作。
        </div>

        <!-- !翻译下面的英文部分 -->
        <div class="content">
            <p>点击<b>"删除我的账号"</b>您将收到一封确认邮件以继续您的删除操作。
            <br><br>
            请注意，此操作不可逆：所有个人数据将被永久删除或匿名化，但<b>参与的竞赛和提交的作品</b>将根据平台的用户协议保留。
            <br><br>
            如果您希望删除您的提交作品或参与的竞赛，请在删除账户之前完成这些操作。
            <br><br>
            删除账户后，您将无法再获得任何您参与的竞赛中的现金奖励。
            </p>
            <!-- <p>By clicking <b>"Delete my account"</b> you will receive a confirmation email to proceed with your account deletion.
            <br><br>
            This action is irreversible: all personal data will be permanently deleted or anonymized, <b>except for competitions and submissions</b> retained under the platform's user agreement.
            <br><br>
            If you wish to delete your submissions or competitions, please do so before deleting your account.
            <br><br>
            You will also no longer be eligible for any cash prizes in competitions you are participating in.
</p> -->
            <div class="ui divider"></div>

            <form class="ui form" id="delete-account-form" onsubmit="{handleDeleteAccountSubmit}">
                <div class="required field">
                    <label for="username">你的用户名</label>
                    <input type="text" id="username" name="username" required oninput="{checkFields}" />
                </div>

                <div class="required field">
                    <label for="confirmation">输入<i>删除我的账号</i>以确认</label>
                    <input type="text" id="confirmation" name="confirmation" required oninput="{checkFields}" />
                </div>

                <div class="required field">
                    <label for="password">确认您的密码</label>
                    <input type="password" id="password" name="password" required />
                </div>

                <button class="ui button fluid delete-button" type="submit" disabled="{isDeleteAccountSubmitButtonDisabled}" >删除我的账号</button>
            </form>
        </div>
    </div>

    <script>
        self = this;
        self.user = user;

        self.isDeleteAccountSubmitButtonDisabled = true;

        self.show_modal = selector => $(selector).modal('show');
        self.hide_modal = selector => $(selector).modal('hide');

        self.checkFields = function() {
            const formValues = $('#delete-account-form').form('get values');
            const username = formValues.username;
            const confirmation = formValues.confirmation;

            if (username === self.user.username && confirmation === "delete my account") {
                self.isDeleteAccountSubmitButtonDisabled = false;
            } else {
                self.isDeleteAccountSubmitButtonDisabled = true;
            }

            self.update();
        }

        handleDeleteAccountSubmit = function(event) {
            event.preventDefault();

            const formValues = $('#delete-account-form').form('get values');

            CODALAB.api.request_delete_account(formValues)
                .done(function (response) {
                    const success = response.success;
                    if (success) {
                        toastr.success(response.message);
                        self.hide_modal('.delete-account.modal')
                    } else {
                        toastr.error(response.error);
                    }
                })
                .fail(function () {
                    toastr.error("An error occured. Please contact administrators");
                })
        }
    </script>

    <style type="text/stylus">
        .title {
            font-size: 24px;
            font-weight: 600;
            color: #24292f;
        }
        .danger {
            color: #db2828;
        }
        .delete-button {
            color: #db2828 !important;
        }
        .delete-button:hover {
            background-color: #db2828 !important;
            color: white !important;
        }
    </style>
</profile-account>