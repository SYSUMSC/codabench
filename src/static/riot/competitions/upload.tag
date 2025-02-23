<competition-upload>
    <div class="ui grid container">
        <div class="eight wide column centered form-empty">
            <div class="ui segment">
                <div class="flex-header">
                    <h1 class="ui header">上传题目</h1>
                    <help_button href="https://github.com/codalab/competitions-v2/wiki/Competition-Creation:-Bundle"
                                 tooltip="了解更多关于竞赛包创建的信息">
                    </help_button>
                </div>

                <!-- 文件选择状态视图 -->
                <form hide="{ listening_for_status || resulting_competition || resulting_details }" class="ui form coda-animated {error: errors}" ref="form" enctype="multipart/form-data">
                    <input-file name="data_file" ref="data_file" error="{errors.data_file}" accept=".zip"></input-file>
                </form>

                <!-- 上传进度状态视图 -->
                <div hide="{ listening_for_status || resulting_competition || resulting_details }" class="ui indicating progress" ref="progress">
                    <div class="bar">
                        <div class="progress">{ upload_progress }%</div>
                    </div>
                </div>

                <!-- 错误状态视图 -->
                <div class="ui message error" show="{ Object.keys(errors).length > 0 }">
                    <div class="header">
                        竞赛包上传出错
                    </div>
                    <ul class="list">
                        <li each="{ error, field in errors }">
                            <strong>{field}:</strong> {error}
                        </li>
                    </ul>
                </div>

                <!-- 竞赛创建任务状态视图 -->
                <div ref="task_status_display" class="coda-animated-slow task-status-display">
                    <div class="ui huge text centered inline loader { active: listening_for_status }">正在解压...</div>

                    <div class="ui success message" show="{ resulting_competition }">
                        <div class="header">
                            竞赛创建成功！
                        </div>
                        <p><a href="{ URLS.COMPETITION_DETAIL(resulting_competition) }">点击此处查看</a>您的新竞赛。</p>
                    </div>

                    <div class="ui negative message" show="{ !listening_for_status && !resulting_competition }">
                        <div class="header">
                            创建失败
                        </div>
                        <p>{ resulting_details }</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        var self = this

        self.clear_form = function () {
            $(':input', self.root).not(':button, :submit, :reset, :hidden').val('')
            self.errors = {}
            self.update()
        }

        self.check_form = function (event) {
            if (event) event.preventDefault()
            var data_file = self.refs.data_file.refs.file_input.value

            if (!data_file || !data_file.endsWith('.zip')) {
                toastr.warning("请选择一个 .zip 文件上传")
                setTimeout(self.clear_form, 1)
                return
            }

            self.clear_form()
            self.prepare_upload(self.upload)()
        }
    </script>
</competition-upload>
