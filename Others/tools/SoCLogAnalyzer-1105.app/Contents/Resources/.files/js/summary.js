$(function(){

    // 写入 Chart URL
    window.SetChartInfo = function (json) {
        let original_json = JSON.parse(json);
        for(var key in original_json){
            var item = $(`[data-uuid="${key}"]`);
            if (item[0]) {
                let a = `<a title="Show Chart" href="${original_json[key]}:chart"></a>`;
                item.html(a);
            }
        }
        // 隐藏 HTML 中的加载动画
        $('.table thead th:nth-child(4)').removeClass('loading');
    };

    // Load ALL
    let $btn = $('#show_more_btn');
    let init_countdown = $btn.data('countdown');
    setTimeout(function xxx() {
        init_countdown--;
        $btn.text(`Load all (${init_countdown})`);
        if (init_countdown>1){
            setTimeout(xxx, 1000);
        }else{
            setTimeout(()=>$('#info_bar').slideUp(300), 500);
        }
    }, 1000)

    // 展开折叠
    let expand_btns = $('.expand-btn');
    if (expand_btns.length > 0){
        let expand = function(){$(this).next('li').toggle(100, expand)};
        let collapse = function(){
            if ($(this).prev('li').hasClass('hidden_item')) {
                $(this).prev('li').slideToggle(100, collapse)
            }};
        expand_btns.on('click', function(e){
            e.stopImmediatePropagation();
            let $this = $(this);
            if ($this.data('status') == 'collapse'){
                $this.siblings('li').eq(5).toggle(100, expand);
                $this.data('status', 'expand');
                $this.text('Collapse...');
            }else{
                $this.prev('li').slideToggle(100, collapse);
                $this.data('status', 'collapse');
                $this.text('Expand...');
            }
        })
    };

    // 滚动到相应位置
    $('a').on('click', function (e) {
        $('.hidden').removeClass('hidden');
        let ele = $(`div[name=${e.currentTarget.name}]`);
        $("html, body").animate(
            {
                scrollTop: $(ele).offset().top
            },
            {
                duration: 400, easing: "swing"
            });
        return false;
    });

    // 滚动到顶部
    $(window).on('scroll', function () {
        let scrollup_btn = $('.scrollup');
        if ($(window).scrollTop() > 100) {
            if (!scrollup_btn.hasClass('back-top')){
                scrollup_btn.addClass('back-top');
            }
        }else{
            if (scrollup_btn.hasClass('back-top')){
                scrollup_btn.removeClass('back-top');
            }
        }
    });

    // 回到顶部
    $('#gotop').click(function(){
        $("html, body").animate(
            {scrollTop: 0},
            {duration: 400, easing: "swing"});
        return 	
    });

    // Cmd Table Options
    var fancyTable_options = {
        pagination: true,	// 开启分页
        perPage: 10,		// 每页元素个数
        globalSearch: true, // 全局搜索
        sortable: true,     // 是否开启排序
        sortColumn: 1,      // 要初始排序的列 0 开始
        sortOrder: 'descending' // Valid values are 'desc', 'descending', 'asc', 'ascending', -1 (descending) and 1 (ascending)
    };

    var fancyTable_instances = new Object();
    $('[name="file"]>div[name]').find('table[id].table').each(function () {
        fancyTable_instances[$(this).prop('id')] = $(this).fancyTable(fancyTable_options);
    });

    $('table').on('click','[data-href]', function(){
        window.location.href = $(this).data('href');
    })

    $('table').on('change', 'select', function() {
        var $ele = $(this),
            $parent_tr = $ele.parents('tr.fancySearchRow'),
            $parent_table = $ele.parents('table[id].table');

        let copy_options = {...fancyTable_options}
        copy_options.perPage = Number($ele.val())
        $parent_tr.remove();
        $parent_table.fancyTable(copy_options);
    })

})