<quota-management>
   
    <div class="ui segment p-4">
        <div class="ui" style="display: flex; flex-direction: row; align-items: center;">
            <!--  标题  -->
            <h2 style="margin-bottom: 0;">配额和清理</h2>

            <!--  配额  -->
            <div style="flex: 0 0 auto; margin-left: auto;">
                配额： {formatSize(storage_used)} / {formatSize(quota)}
            </div>
        </div>

        <!--  表格  -->
        <table class="ui celled compact table">
            <tbody>
                <!--  未使用任务  -->
                <tr>
                    <td>未使用任务 <span show="{unused_tasks > 0}">(<b>{unused_tasks}</b>)</span></td>
                    <td>
                    <button class="ui red right floated labeled icon button {disabled: unused_tasks === 0}" onclick="{delete_unused_tasks}">
                        <i class="icon trash"></i>
                        删除未使用任务
                    </button>
                    </td>
                </tr>
                <!--  未使用数据集和程序  -->
                <tr>
                    <td>未使用数据集和程序 <span show="{unused_datasets_programs > 0}">(<b>{unused_datasets_programs}</b>)</span></td>
                    <td>
                    <button class="ui red right floated labeled icon button {disabled: unused_datasets_programs === 0}" onclick="{delete_unused_datasets}">
                        <i class="icon trash"></i>
                        删除未使用数据集/程序
                    </button>
                    </td>
                </tr>
                <!--  未使用提交  -->
                <tr>
                    <td>未使用提交 <span show="{unused_submissions > 0}">(<b>{unused_submissions}</b>)</span></td>
                    <td>
                        <button class="ui red right floated labeled icon button {disabled: unused_submissions === 0}" onclick="{delete_unused_submissions}">
                        <i class="icon trash"></i>
                        删除未使用提交
                    </button>
                    </td>
                </tr>
                <!--  失败的提交  -->
                <tr>
                    <td>失败的提交 <span show="{failed_submissions > 0}">(<b>{failed_submissions}</b>)</span></td>
                    <td>
                        <button class="ui red right floated labeled icon button {disabled: failed_submissions === 0}" onclick="{delete_failed_submissions}">
                        <i class="icon trash"></i>
                        删除失败的提交
                    </button>
                    </td>
                </tr>
            </tbody>
            
        </table>
    </div>

    <script>
        // 初始化变量
        let self = this
        self.unused_tasks = 0
        self.unused_datasets_programs = 0
        self.unused_submissions = 0
        self.failed_submissions = 0
        self.quota = 0
        self.storage_used = 0

        // 页面加载时获取清理数据和配额
        self.on('mount', () => {
            self.update()
            self.get_cleanup()
            self.get_quota()
        })

        self.get_cleanup = function () {
            CODALAB.api.get_user_quota_cleanup()
                .done(function (data) {
                    self.unused_tasks = data.unused_tasks
                    self.unused_datasets_programs = data.unused_datasets_programs
                    self.unused_submissions = data.unused_submissions
                    self.failed_submissions = data.failed_submissions
                    self.update()
                })
                .fail(function (response) {
                    toastr.error("无法加载清理数据")
                })
        }

        self.get_quota = function () {
            CODALAB.api.get_user_quota()
                .done(function (data) {
                    self.quota = data.quota
                    self.storage_used = data.storage_used
                    self.update()
                })
                .fail(function (response) {
                    toastr.error("无法加载配额")
                })
        }

        /*
        删除操作函数
        */

        // 删除未使用任务
        self.delete_unused_tasks = function(){
            if (confirm(`您确定要永久删除所有未使用的任务吗？`)) {

                CODALAB.api.delete_unused_tasks()
                    .done(function (data) {
                        if(data.success){
                            self.unused_tasks = 0
                            toastr.success(data.message)
                            self.update()
                            CODALAB.events.trigger('reload_tasks')
                            CODALAB.events.trigger('reload_datasets')
                            self.get_cleanup()
                        }else{
                            toastr.error(data.message)
                        }
                    })
                    .fail(function (response) {
                        toastr.error("未使用任务删除失败！")
                    })
            }
        }

        // 删除未使用数据集和程序
        self.delete_unused_datasets = function(){
            if (confirm(`您确定要永久删除所有未使用的数据集和程序吗？`)) {

                CODALAB.api.delete_unused_datasets()
                    .done(function (data) {
                        if(data.success){
                            self.unused_datasets_programs = 0
                            toastr.success(data.message)
                            self.update()
                            CODALAB.events.trigger('reload_datasets')
                        }else{
                            toastr.error(data.message)
                        }
                    })
                    .fail(function (response) {
                        toastr.error("未使用数据集和程序删除失败！")
                    })
            }
        }

        // 删除未使用提交
        self.delete_unused_submissions = function(){
            if (confirm(`您确定要永久删除所有未使用的提交吗？`)) {

                CODALAB.api.delete_unused_submissions()
                    .done(function (data) {
                        if(data.success){
                            self.unused_submissions = 0
                            toastr.success(data.message)
                            self.update()
                            CODALAB.events.trigger('reload_submissions')
                        }else{
                            toastr.error(data.message)
                        }
                    })
                    .fail(function (response) {
                        toastr.error("未使用提交删除失败！")
                    })
            }
        }

        // 删除失败的提交
        self.delete_failed_submissions = function(){
            if (confirm(`您确定要永久删除所有失败的提交吗？`)) {

                CODALAB.api.delete_failed_submissions()
                    .done(function (data) {
                        if(data.success){
                            self.failed_submissions = 0
                            toastr.success(data.message)
                            self.update()
                            CODALAB.events.trigger('reload_submissions')
                        }else{
                            toastr.error(data.message)
                        }
                    })
                    .fail(function (response) {
                        toastr.error("失败的提交删除失败！")
                    })
            }
        }

        // 工具函数
        self.formatSize = function(size) {
            return pretty_bytes(size);
        }

        CODALAB.events.on('reload_quota_cleanup', self.get_cleanup)

    </script>

</quota-management>
