#
#                   IMDB bot
#            Author: Z3NTL3 (Efdal)
#                  License: GNU
# 

import std / [httpclient, os, parseutils, strformat, uri, xmltree, json, asyncdispatch, strutils]
import nimquery
from std/htmlparser import parseHtml 

const
    API {.used.} = "https://www.imdb.com/title"
    PATH {.used.} = "/"
    TIMEOUT_ENV = if existsEnv("ALEXA_PX_TIMEOUT"): getEnv("ALEXA_PX_TIMEOUT") else: "2000"
    BOLD = "\x1b[1m"
    RESET = "\x1b[0m"
    RED = "\x1b[31m"
    ILLEGAL = ["#","<",">","$","+","%", "!", ":", "`", "&", "{","}", "\"","'", "|"]

type
    PARAMS = ref object of RootObj
        name: string
    PAYLOAD {.used.} = ref object of PARAMS
    PROXIFY = ref object of RootObj
        useProxy: bool
        proxy_url: string
        

var 
    proxyURL = "nothing"
    HEADERS = @[
        ("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"),
        ("cache-control", "must-revalidate")
    ]
    defaultHeaders = newHttpHeaders(HEADERS)
    TIMEOUT = 2000
let
    DATASET_DIR = getAppDir().joinPath("dataset")

when isMainModule:
    discard parseInt(TIMEOUT_ENV,TIMEOUT,0)

    assert fileExists(getAppDir().joinPath("list.txt"))

    try:
        if existsEnv("http_proxy"):
            proxyURL = getEnv("http_proxy","nothing")
        elif existsEnv("https_proxy"):
            proxyURL = getEnv("https_proxy","nothing")
        else: discard

    except CatchableError:
        var err = getCurrentException()
        echo err.msg
        quit -1

    var Proxy: PROXIFY
    Proxy = PROXIFY(use_proxy: if(proxyURL == "" or proxyURL == "nothing"): false else: true, proxy_url:proxyURL)
    
    proc gatherStats(timeoutMS: int = 2000, id: string): Future[void] {.async.} =
        {.cast(gcsafe).}
        try:
            var client: AsyncHttpClient
            if(Proxy.useProxy): client = newAsyncHttpClient(proxy=newProxy(Proxy.proxy_url))
            else: client = newAsyncHttpClient()

            client.headers = defaultHeaders

            var req = client.getContent(fmt"{API}{PATH}{id}")
            var tmOut = await req.withTimeout(timeoutMS)

            var DOM: XmlNode = await(req).parseHtml()
            var rating = DOM.querySelector("[data-testid='hero-rating-bar__aggregate-rating__score']")
                .querySelector("[class='sc-bde20123-1 iZlgcd']").innerText()
        
            var genreTab = DOM.querySelector("[class=\"ipc-chip-list__scroller\"]").querySelectorAll("[class=\"ipc-chip ipc-chip--on-baseAlt\"]")
            var genres = newSeq[string]()

            for genre in genreTab.items():
                genres.add(genre.innerText())

            var description = DOM.querySelector("[class=\"sc-5f699a2-0 kcphyk\"]").innerText()
            var popularity = DOM.querySelector("[class=\"sc-5f7fb5b4-1 bhuIgW\"]").innerText()
            var title = DOM.querySelector("[class=\"sc-afe43def-1 fDTGTb\"]").innerText()

            for disallowed in ILLEGAL.items():
                title = title.replace(disallowed)
            
            var file = DATASET_DIR.joinPath(title).joinPath("data.json")
            var dataset = %*{ 
                "title": title,
                "description": description,
                "popularity": popularity,
                "rating": rating,
                "genres": genres
            }

            createDir(DATASET_DIR.joinPath(title))
            var f = open(file, fmReadWrite)
            f.write(pretty(dataset,4))
            f.close()

            client.close()

            echo fmt"Task for {BOLD}{title}{RESET} completed [{BOLD}{file}{RESET}]"
        except CatchableError:
            echo fmt"{BOLD}{RED}[ Something went wrong ] {RESET}"
            var err = getCurrentException()
            echo err.msg
    var tasks = newSeq[Future[void]]()
    var imdbs = open(getAppDir().joinPath("list.txt"), bufSize=2048)
    
    var line: string

    while imdbs.readLine(line):
        tasks.add(gatherStats(TIMEOUT,line))
    all(tasks).waitFor()

    echo "\nTasks completed"