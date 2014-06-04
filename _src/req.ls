'use strict';

window.Req = (
    reqs = (
        \jsPoweredByJQuery :
            [
                {
                    name:'jQuery',
                    url:'//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js',
                    type:'js',
                    success: -> console.log "jquery OK!",
                    fail: -> ,
                    test: -> (((typeof $) === 'function') && ((typeof $.fn.jquery) === 'string'))
                },
                {
                    name:'bootstrap',
                    url:'//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js',
                    type:'js',
                    success: -> console.log "bootstrap OK!",
                    # fail: -> ,
                    # test: -> 
                },
            ]
        \bootstrapCSS :
            [
                {
                    # name:'bootstrap',
                    url:'/res/bootstrap.min.css',
                    type:'css',
                    success: ->  console.log("bootstrapCSS OK!"),
                    # fail: -> ,
                    # test: -> 
                }
            ]
    ),
    whenCompleteAllReq = ->,
    info = off,
    dontFireAtOnce = false,
    ) ->

    instance = 
        reqs : reqs
        
    reqs = instance.reqs
    failSignal = "{`F`}"
    successSignal = "{`OK`}"

    info = 
        if (info and console.log) 
            then ((msg,title) -> if title then console.log "[ Req:#title ] => #msg" else console.log msg) 
            else (->)

    warn = ((msg,title) -> if title then console.log "[ Req:#title ] => #msg" else console.log msg)

    typeProcessor =
        unknown : (data,name) -> data
        js : (data,name) ->
            JS = document.createElement \script
            JS.innerHTML = data
            JS.setAttribute "class","js_added_by_req"
            JS.setAttribute "id","JS_"+name

            info "[ js:#name ] => inserting into document..."
            (document.getElementsByTagName 'head')[0].appendChild JS
            JS
        css : (data,name) ->
            CSS = document.createElement \style
            CSS.innerHTML = data
            CSS.setAttribute "class","css_added_by_req"
            CSS.setAttribute "id","CSS_"+name

            info "[ css:#name ] => inserting into document..."
            (document.getElementsByTagName 'head')[0].appendChild CSS
            CSS
        json : (data,name) ->
            try
                return (JSON and JSON.parse data) or eval(data);
            catch error
                message "[ json:#name ] => parsing failed! Exception:"
                warn error,true
                failSignal

    instance.hasXDomainRequest = typeof XDomainRequest isnt \undefined
    instance.xhrMethods = 
        * "XDomainRequest()"
        * "ActiveXObject(\"Msxml2.XMLHTTP.3.0\")"
        * "ActiveXObject(\"Msxml2.XMLHTTP.6.0\")"
        * "XMLHttpRequest()"
        * "ActiveXObject(\"Microsoft.XMLHTTP\")"

    XHR = instance.XHR = (
        URL = failSignal,
        whenSuccess = ->,
        whenFail = ->,
        whenEnd = ->,
        name = failSignal,
        tag = false
        ) ->
        if URL is failSignal then throw "xhr require URL parameter!"
        if name is failSignal then name = "{#URL}";

        funTitle = \XHR

        aFailure = ->
            warn "request for [ #name ] failed, status=\"#{request.statusText}\"",funTitle
            whenFail request,tag
            whenEnd request,tag

        aSuccess = ->
            info "request for [ #name ] success",funTitle
            whenSuccess request.responseText,request,tag
            whenEnd request,tag

        readystatechangeHandler = ->
            if request.readyState is 4 =>
                if request.status in [200,304] then aSuccess!
                else aFailure!

        crossDomain = !!URL.match("//")

        request = (->
            try return eval "new " + instance.xhrMethod

            for i in [(!crossDomain) + 0 to instance.xhrMethods.length - 1] by 1 =>
                try return eval "new " + ( instance.xhrMethod = instance.xhrMethods[i] )

            throw "This browser does NOT support any AJAX request, aborting..."
            )!

        info "Using "+instance.xhrMethod,funTitle

        if instance.hasXDomainRequest then delete instance.xhrMethod

        if instance.xhrMethod is \XDomainRequest =>
            request.onload = aSuccess
            request.onerror = aFailure
        else =>
            request.onreadystatechange = readystatechangeHandler

        request.open("GET",URL,true);

        info "sending [ #name ] ...",funTitle
        request.send!
        request

    reqQueue = instance.reqQueue = (
        q = [],
        name = "reqQueue",
        ) ->

        reqQueueInstance = {}
        funTitle = \reqQueue
        alreadyOKMsg = "already pass its test, skipped."
        noTestMsg = "no test function"

        k = -1
        exeing = false

        reqQueueInstance.enqueue = (req) ->
            if k is not -1 then throw "reqQueue fired! refused to enqueue."
            q.push req
            reqQueueInstance

        reqQueueInstance.fire = (whenAllComplete = ->) ->
            if k is not -1 then throw "reqQueue fired! refused to fire again."
            k++
            i = 0
            if typeof q[i] isnt \object =>
                warn "A valid reqQueue should be an array, reqQueue:"
                warn q
                return false
            while r = arrangeReqs q[ i++ ] =>
                r.reqResult = {}

                try
                    r.reqResult.test = r.reqResult.done = r.test!
                catch e
                    r.reqResult.done = false
                    r.reqResult.test = noTestMsg

                if not r.reqResult.done =>
                    r.reqResult.xhr = XHR(
                        r.url,
                        ((data,request,r) ->
                            r.reqResult.data = data
                            r.reqResult.xhrSuccess = true
                            info "#{r.type}|#{r.name} : data ready!",funTitle
                        ),
                        ((request,r) ->
                            r.reqResult.data = false
                            r.reqResult.xhrSuccess = false
                            warn "#{r.type}|#{r.name} : fail to get data!",funTitle
                        ),
                        ((request,r) ->
                            r.reqResult.done = true
                            if ( k < q.length ) and not exeing =>
                                exeing = true
                                exe!
                                exeing = false
                        ),
                        "#{r.type}|#{r.name}",r)
                else
                    r.reqResult.xhr = alreadyOKMsg
                    r.reqResult.xhrSuccess = alreadyOKMsg
                    info "#type|#name : #alreadyOKMsg",funTitle
            reqQueueInstance

        exe = ->
            r = q[k]
            type = r.type
            name = r.name
            reqResult = r.reqResult

            try if not reqResult.done then return false 
            catch e
                return false 

            if reqResult.hasContent = (typeof reqResult.data is \string) =>
                info "#type|#name : start to process data...",funTitle
                reqResult.typeResult = typeProcessor[r.type](reqResult.data,r.name);
                reqResult.typeProcess = reqResult.typeResult isnt failSignal

            if (not reqResult.test) and reqResult.test isnt noTestMsg =>
                info "#type|#name : start to test...",funTitle
                reqResult.test = r.test!

            info "#type|#name : xhrSuccess:#{reqResult.xhrSuccess}, test:#{reqResult.test}, typeProcess:#{reqResult.typeProcess}",funTitle

            if reqResult.xhrSuccess and reqResult.test and reqResult.typeProcess =>
                if reqResult.hasContent =>
                    info "#type|#name : calling success:function(precessData) ..."
                    r.success reqResult.typeResult,reqResult
                else
                    info "#type|#name : calling success:function(reqResult) ..."
                    r.success reqResult
            else
                warn "#type|#name : calling fail:function(reqResult) ..."
                r.fail reqResult

            if ++k >= q.length then return true
            exe!

        arrangeReqs = (req) ->
            if typeof req isnt \object =>
                if typeof req isnt \undefined =>
                    warn "There is an invalid req! A valid req should be an object, this req:",funTitle
                    warn req
                return false
            if typeof req.url isnt \string => 
                warn "There is an invalid req objet! A valid req object should at least contains url property, this req:",funTitle
                warn r
                return false
            if typeof req.fail isnt \function then req.fail = ->
            if typeof req.success isnt \function then req.success = ->
            if req.type not of typeProcessor then req.type = \unknown
            url = req.url
            if typeof req.name isnt \string then req.name = "@#url"
            req
        reqQueueInstance

    instance.start = ->
        funTitle = \start

        info "Req started",funTitle

        process = 0
        for k,q of reqs =>
            process++
            info "reqQueue|#k : starting to process ...",funTitle
            tmp = new reqQueue(q,k)
            tmp.fire(->
                if (--process) <= 0 then whenCompleteAllReq!
            )
        instance

    if not dontFireAtOnce then instance.start!

    info "Req instance:"
    info instance

    instance
