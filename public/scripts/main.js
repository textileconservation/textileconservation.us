"use strict";
!function() {
    for (var e = document.querySelectorAll("[data-popover]"), n = document.querySelectorAll(".popover"), t = 0; t < e.length; t++)
        e[t].addEventListener("click", r);
    function o(e) {
        for (var t = 0; t < n.length; t++)
            n[t].classList.remove("popover-open")
    }
    function r(e) {
        e.preventDefault(),
        document.querySelector(this.getAttribute("href")).classList.contains("popover-open") ? document.querySelector(this.getAttribute("href")).classList.remove("popover-open") : (o(),
        document.querySelector(this.getAttribute("href")).classList.add("popover-open")),
        e.stopImmediatePropagation()
    }
    document.addEventListener("click", o)
}()