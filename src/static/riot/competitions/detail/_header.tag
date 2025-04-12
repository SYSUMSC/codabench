<comp-detail-header>
    <div class="ui relaxed grid">
        <div class="row">
            <div class="three wide column">
                <img class="ui medium circular image competition-image" alt="竞赛 Logo" src="{ competition.logo }">
            </div>
            <div class="ten wide column">
                <div class="ui grid">
                    <div class="row">
                        <div class="column">
                            <div class="competition-name underline">
                                {competition.title}
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="reward-container" if="{competition.reward}">
                            <img class="reward-icon" src="/static/img/trophy.png">
                            <div class="reward-text">{competition.reward}</div>
                        </div>
                    </div>
                    <div if="{competition.admin}">
                        <a href="{URLS.COMPETITION_EDIT(competition.id)}" class="ui button">编辑</a>
                        <button class="ui small button" onclick="{show_modal.bind(this, '.manage-participants.modal')}">
                            参与者
                        </button>
                        <button class="ui small button" onclick="{show_modal.bind(this, '.manage-submissions.modal')}">
                            提交
                        </button>
                        <button class="ui small button" onclick="{show_modal.bind(this, '.manage-competition.modal')}">
                            数据包
                        </button>
                        <button class="ui small button" onclick="{show_modal.bind(this, '.migration.modal')}">
                            迁移
                        </button>
                    </div>
                    <div class="row">
                        <div class="column">
                            <!-- 主信息 -->

                            <div class="info-container">
                                <!-- 出题人 -->
                                <div class="info-card">
                                    <span class="emoji-icon">👥</span>
                                    <div class="detail-content">
                                        <div class="detail-label">出题人：</div>
                                        <span class="detail-item"><a href="/profiles/user/{competition.created_by}"
                                                target="_BLANK">{competition.owner_display_name}</a></span>
                                        <span if="{competition.contact_email}">(<span
                                                class="contact-email">{competition.contact_email}</span>)</span>
                                    </div>
                                </div>

                                <!-- 时间信息 -->
                                <div class="info-card">
                                    <span class="emoji-icon">⏰</span>
                                    <div class="detail-content">
                                        <div class="time-group">
                                            <div class="detail-label">{has_current_phase(competition) ? '当前阶段结束' :
                                                '当前有效阶段'}:</div>
                                            <span class="detail-item">{get_end_date(competition)}</span>
                                        </div>
                                        <div class="time-group">
                                            <div class="detail-label">服务器时间：</div>
                                            <span class="detail-item" id="server_time">{pretty_date(CURRENT_DATE_TIME)}</span>
                                        </div>
                                    </div>
                                    </div>
                                    </div>
                                    <!-- Docker 镜像和密钥 URL -->
                                    <div class="info-card">
                                        <span class="emoji-icon">ℹ️</span>
                                        <div class="detail-content">
                                            <div class="detail-label">Docker镜像</div>
                                            <div class="detail-item">
                                                <span id="docker-image">{ competition.docker_image }</span>
                                            <span onclick="{copy_docker_url}" class="copy-trigger">
                                                <i class="ui copy icon"></i>
                                            </span>
                                            </div>
                                        <div class="detail-label" if="{ competition.admin }">竞赛密钥</div>
                                        <div class="detail-item" if="{ competition.admin }">
                                            <span id="secret-url">https://{ URLS.SECRET_KEY_URL(competition.id, competition.secret_key) }</span>
                                            <div onclick="{copy_secret_url}" class="copy-trigger">
                                                <i class="ui copy icon"></i>
                                            </div>
                                            </div>
                                            </div>
                                            </div>

                            <!-- 竞赛报告 -->
                                <div class="info-card" if="{competition.report}">
                                    <span class="emoji-icon">📊</span>
                                    <div class="detail-content">
                                        <div class="detail-label">分析报告</div>
                                        <div class="detail-item">
                                            <span id="report-url">{ competition.report }</span>
                                            <span onclick="{copy_report_url}" class="copy-trigger">
                                                <i class="ui copy icon"></i>
                                            </span>
                                        </div>
                                        </div>
                                        </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- 管理竞赛模态框 -->
    <div class="ui manage-competition modal" ref="files_modal">
        <div class="content">
            <div class="ui dropdown button">
                <i class="download icon"></i>
                <div class="text">创建竞赛数据包</div>
                <div class="menu">
                    <div class="parent-modal item" onclick="{create_dump.bind(this, true)}">
                        <!-- true表示包含密钥 -->
                        包含密钥的数据包
                    </div>
                    <div class="parent-modal item" onclick="{create_dump.bind(this, false)}">
                        <!-- false表示包含文件 -->
                        包含文件的数据包
                    </div>
                </div>
            </div>

            <!--  <button class="ui icon button" onclick="{create_dump}">
                <i class="download icon"></i> 创建竞赛数据包
            </button>  -->
            <button class="ui icon button" onclick="{update_files}">
                <i class="sync alternate icon"></i> 刷新表格
            </button>
            <table class="ui table">
                <thead>
                    <tr>
                        <th>文件</th>
                    </tr>
                </thead>
                <tbody>
                    <tr show="{files.bundle}">
                        <td class="selectable">
                            <a href="{files.bundle ? files.bundle.url : ''}">
                                <i class="file archive outline icon"></i>
                                数据包: {files.bundle ? files.bundle.name : ''}
                            </a>
                        </td>
                    </tr>
                    <tr each="{file in files.dumps}" show="{files.dumps}">
                        <td class="selectable">
                            <a href="{file.url}">
                                <i class="file archive outline icon"></i>
                                数据包: {file.name}
                            </a>
                        </td>
                    </tr>
                    <tr>
                        <td show="{!files.dumps && !files.bundle}">
                            <em>暂无文件</em>
                        </td>
                    </tr>
                    <tr>
                        <td class="center aligned" if="{tr_show}">正在生成数据包，请刷新</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <!-- 管理提交模态框 -->
    <div class="ui manage-submissions large modal" ref="sub_modal">
        <div class="content">
            <submission-manager admin="{competition.admin}" competition="{ competition }"></submission-manager>
        </div>
    </div>

    <!-- 管理参与者模态框 -->
    <div class="ui manage-participants modal" ref="participant_modal">
        <div class="content">
            <participant-manager></participant-manager>
        </div>
    </div>

    <!-- 手动迁移模态框 -->
    <div class="ui migration modal" ref="migration_modal">
        <div class="content">
            <table class="ui table">
                <thead>
                    <tr>
                        <th colspan="100%">
                            请选择一个阶段进行迁移
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <tr each="{phase, index in competition.phases}">
                        <td>{phase.name}</td>
                        <td class="collapsing">
                            <button if="{index !== competition.phases.length - 1}" class="ui button"
                                onclick="{migrate_phase.bind(this, phase.id)}">
                                迁移
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <script>
        let self = this

        self.competition = {}
        self.files = []

        self.tr_show = false

        CODALAB.events.on('competition_loaded', function (competition) {
            competition.admin = CODALAB.state.user.has_competition_admin_privileges(competition)
            self.competition = competition
            self.update()
            if (self.competition.admin) {
                self.update_files()
            }
            $('.dropdown', self.root).dropdown()
        })

        self.close_modal = selector => $(selector).modal('hide')
        self.show_modal = selector => $(selector).modal('show')

        self.create_dump = (keys_instead_of_files) => {
            CODALAB.api.create_competition_dump(self.competition.id, keys_instead_of_files)
                .done(data => {
                    self.tr_show = true
                    toastr.success("成功！您的竞赛数据包正在创建中。")
                    self.update()
                })
                .fail(response => {
                    toastr.error("创建竞赛数据包时发生错误。")
                })
        }

        self.update_files = (e) => {
            CODALAB.api.get_competition_files(self.competition.id)
                .done(data => {
                    self.files = data
                    self.tr_show = false
                    self.update()
                })
                .fail(response => {
                    toastr.error('获取竞赛文件时发生错误')
                })
        }


        self.copy_secret_url = function () {
            let range = document.createRange();
            range.selectNode(document.getElementById("secret-url"));
            window.getSelection().removeAllRanges(); // 清除当前选择
            window.getSelection().addRange(range); // 选择文本
            document.execCommand("copy");
            window.getSelection().removeAllRanges(); // 取消选择
            $('.send-pop-secret').popup('toggle')
        }

        self.copy_docker_url = function () {
            let range = document.createRange();
            range.selectNode(document.getElementById("docker-image"));
            window.getSelection().removeAllRanges(); // 清除当前选择
            window.getSelection().addRange(range); // 选择文本
            document.execCommand("copy");
            window.getSelection().removeAllRanges(); // 取消选择
            $('.send-pop-docker').popup('toggle')
        }

        self.copy_report_url = function () {
            let range = document.createRange();
            range.selectNode(document.getElementById("report-url"));
            window.getSelection().removeAllRanges(); // 清除当前选择
            window.getSelection().addRange(range); // 选择文本
            document.execCommand("copy");
            window.getSelection().removeAllRanges(); // 取消选择
            $('.send-pop-report').popup('toggle')
        }

        self.has_current_phase = function (competition) {
            let current_phase = _.find(competition.phases, { status: 'Current' })
            return current_phase ? true : false
        }

        self.get_end_date = function (competition) {
            if (self.has_current_phase(competition)) {
                let end_date = _.get(_.find(competition.phases, { status: 'Current' }), 'end')
                return end_date ? pretty_date(end_date) : '从未'
            } else {
                return '无'
            }

        }

        self.migrate_phase = function (phase_id) {
            CODALAB.api.manual_migration(phase_id)
                .done(data => {
                    toastr.success("该阶段的迁移将很快开始。")
                    self.close_modal(self.refs.migration_modal)
                })
                .fail(error => {
                    toastr.error('迁移此阶段时出现问题。')
                })
        }

    </script>

    <style type="text/stylus">
        $primary = #2c3f4c
        $accent = #008c8c
        $secondary = #6c757d
        $lightbg = #f8f9fa
        $emoji-color = #4a90e2

        .info-container
            display flex
            flex-wrap wrap
            gap 1.5rem
            margin 1.5rem 0

        .info-card
            flex 1 1 280px
            min-width 280px
            padding 1.2rem
            background lighten($lightbg, 4%)
            border-radius 15px
            box-shadow 2px 2px 8px rgba(0,0,0,0.1)
            display flex
            align-items center
            gap 1rem
            transition all 0.3s ease
            //margin-bottom 1rem

            &:hover
                transform translateY(-3px)
                box-shadow 0 4px 12px rgba(0,0,0,0.15)

            .emoji-icon
                font-size 1.8rem
                width 40px
                height 40px
                display flex
                align-items center
                justify-content center
                color $emoji-color
                filter drop-shadow(0 2px 4px rgba($emoji-color, 0.2))
                transition all 0.3s ease

            .detail-content
                flex 1

                .detail-label
                    font-size 0.9em
                    color $accent
                    margin-top 0.6rem
                    margin-bottom 0.3rem

                .detail-item
                    font-size 1.1em
                    font-weight 500
                    color $primary

                .time-group
                    margin-bottom 0.8rem
                    &:last-child
                        margin-bottom 0

        .copy-trigger
            display inline-block
            cursor pointer
            transition all 0.3s ease
            margin-left 0.8rem
            color lighten($primary, 30%)

            &:hover
                transform scale(1.1)
                color $accent
                filter drop-shadow(0 2px 4px rgba($accent, 0.2))
            &:active
                transform scale(0.9)


        .competition-secret-key
            display flex
            align-items center
            margin 1rem 0
            padding 0.8rem
            background $lightbg
            border-radius 6px
            font-size 0.95em

            span[class$='-label']
                color $accent
                font-weight 500
                min-width 90px

        .competition-secret-key
            font-size 13px

        .contact-email
            font-size 1em
            color $teal
            font-family 'Overpass Mono', monospace

        .secret-label
            color $red

        .docker-label
            color $teal

        .report-label
            color $teal

        .secret-url
            color $blue

        .competition-name
            color $blue
            font-size 3em
            height auto
            line-height 1.1em
            text-transform uppercase
            font-weight 800

        .copy.icon
            cursor pointer

        .competition-image
            padding: 1rem
            box-shadow 3px 3px 5px darkgrey

        .underline
            border-bottom 1px solid $teal
            display inline-block
            line-height 0.9em

        .tiny.left.labeled.button
            display flex
            margin-top 15px
            justify-content flex-end

            .ui.tiny.button
                width 120px
                text-transform uppercase
                font-weight 100

        .ui.table
            color $blue !important

            thead > tr > th
                color $blue !important
                background-color $lightblue !important

        .reward-container
            background linear-gradient(to right, #ff9966, #ff5e62)
            color #fff
            border 1px solid #E6E9EB
            border-radius 2rem
            padding 1rem
            display flex
            align-items center
            margin-left 1rem

        .reward-icon
            width 40px
            height 40px
            margin-right 10px

        .reward-text
            font-size 24px
            font-weight 900
            display inline-block
    </style>
</comp-detail-header>