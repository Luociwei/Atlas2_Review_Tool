/*!
 * 用于隐藏长列表
 * 2021 Carlos Wu
 */
(function ($) {
    $.fn.simpleLoadMore = function (options) {
        var settings = $.extend({
            count: 5,
            btnHTML: '',
            item: ''
        }, options);

        var $loadMore = $(this);

        $loadMore.each(function (i, el) {
            var $thisLoadMore = $(this);
            var $items = $thisLoadMore.find(settings.item);
            var btnHTML = settings.btnHTML ? settings.btnHTML :`<a href="#" class="load-more__btn">Load more↓</a>`;
            var $btnHTML = $(btnHTML);
            // 添加 classes
            $thisLoadMore.addClass('load-more');
            $items.addClass('load-more__item');
            // 添加按钮
            if (!$thisLoadMore.find('.load-more__btn').length && $items.length > settings.count) {
                $thisLoadMore.append($btnHTML);
            }
            $btn = $thisLoadMore.find('.load-more__btn');
            // Check if button is not present. If not, then attach $btnHTML to the $btn variable.
            if (!$btn.length) {
                $btn = $btnHTML;
            }
            // 隐藏超过的count数目的元素
            if ($items.length > settings.count) {
                $items.slice(settings.count).hide();
            }
            // 按钮点击事件
            $btn.on('click', function (e) {
                e.preventDefault();
                var $this = $(this),
                    $updatedItems = $items.filter(':hidden').slice(0, 9999);
                if ($updatedItems.length > 0) {
                    $updatedItems.fadeIn();
                }
                // if ($updatedItems.length < settings.count) {
                //     $this.remove();
                // }
                $this.remove();
            });
        });
    }
}(jQuery));