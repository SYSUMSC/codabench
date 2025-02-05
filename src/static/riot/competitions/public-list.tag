<public-list>
    <h1>公开基准测试和竞赛</h1>
    <div class="pagination-nav">
        <button show="{competitions.previous}" onclick="{handle_ajax_pages.bind(this, -1)}" class="float-left ui inline button active">上一页</button>
        <button hide="{competitions.previous}" disabled="disabled" class="float-left ui inline button disabled">上一页</button>
        第 { current_page } 页，共 {Math.ceil(competitions.count/competitions.page_size)} 页
        <button show="{competitions.next}" onclick="{handle_ajax_pages.bind(this, 1)}" class="float-right ui inline button active">下一页</button>
        <button hide="{competitions.next}" disabled="disabled" class="float-right ui inline button disabled">下一页</button>
    </div>
    <div id="loading" class="loading-indicator" show="{!competitions}">
        <div class="spinner"></div>
    </div>
    <div each="{competition in competitions.results}">
            <div class="tile-wrapper">
                <div class="ui square tiny bordered image img-wrapper">
                    <img src="{competition.logo_icon ? competition.logo_icon : competition.logo}" loading="lazy">
                </div>
                <a class="link-no-deco" href="../{competition.id}">
                    <div class="comp-info">
                        <h4 class="heading">
                            {competition.title}
                        </h4>
                        <p class="comp-description">
                            { pretty_description(competition.description)}
                        </p>
                        <p class="organizer">
                            <em>组织者: <strong>{competition.created_by}</strong></em>
                        </p>
                    </div>
                </a>
                <div class="comp-stats">
                    {pretty_date(competition.created_when)}
                    <div if="{!competition.reward && !competition.report}" class="ui divider"></div>
                    <div>
                        <span if="{competition.reward}"><img width="30" height="30" src="/static/img/trophy.png"></span>
                        <span if="{competition.report}"><a href="{competition.report}" target="_blank"><img width="30" height="30" src="/static/img/paper.png"></span></a>
                    </div>
                    <strong>{competition.participants_count}</strong> 位参与者
                </div>
            </div>
    </div>
    <div class="pagination-nav" hide="{(competitions.count < 10)}">
        <button show="{competitions.previous}" onclick="{handle_ajax_pages.bind(this, -1)}" class="float-left ui inline button active">上一页</button>
        <button hide="{competitions.previous}" disabled="disabled" class="float-left ui inline button disabled">上一页</button>
        第 { current_page } 页，共 {Math.ceil(competitions.count/competitions.page_size)} 页
        <button show="{competitions.next}" onclick="{handle_ajax_pages.bind(this, 1)}" class="float-right ui inline button active">下一页</button>
        <button hide="{competitions.next}" disabled="disabled" class="float-right ui inline button disabled">下一页</button>
    </div>
<script>
    var self = this
    self.competitions = {}

    self.one("mount", function () {
        self.update_competitions_list(self.get_url_page_number_or_default())
    })

    self.handle_ajax_pages = function (num){
        $('.pagination-nav > button').prop('disabled', true)
        self.update_competitions_list(self.get_url_page_number_or_default() + num)
    }

    self.update_competitions_list = function (num) {
        self.current_page = num;
        $('#loading').show(); // 显示加载指示器
        $('.pagination-nav').hide(); // 隐藏分页导航

        // 处理数据获取成功的回调
        function handleSuccess(response) {
            self.competitions = response;
            $('#loading').hide(); // 隐藏加载指示器
            $('.pagination-nav').show(); // 显示分页导航
            history.pushState("", document.title, "?page=" + self.current_page);
            $('.pagination-nav > button').prop('disabled', false);
            self.update();
        }
        // 通过 AJAX 获取数据
        return CODALAB.api.get_public_competitions({"page": self.current_page})
            .fail(function (response) {
                $('#loading').hide(); // 隐藏加载指示器
                $('.pagination-nav').show(); // 显示分页导航
                toastr.error("无法加载竞赛列表");
            })
            .done(handleSuccess);
    };

    self.pretty_date = function (date_string) {
        if (!!date_string) {
            return luxon.DateTime.fromISO(date_string).toLocaleString(luxon.DateTime.DATE_FULL)
        } else {
            return ''
        }
    }

    self.pretty_description = function(description){
        return description.substring(0,120) + (description.length > 120 ? '...' : '') || ''
    }
</script>
</public-list>
