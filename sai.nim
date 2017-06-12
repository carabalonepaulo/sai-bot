#[
20 episódios por página
]#

import httpclient, htmlparser, xmltree
import strutils, streams, re
import math, times, encodings

type SearchItem = object
    title*: string
    url*: string

type Information = object
    title*: string
    url*: string
    genre*: string
    author*: string
    director*: string
    company*: string
    lastEpisode*: string
    year*: string
    pages*: int

type Episode = object
    duration*: TimeInfo # parse(str, "mm:ss")
    url*: string
    image*: string
    title*: string

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * $: Overload do método que transforma o objeto em string.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc `$`(x: SearchItem): string =
    return "<Searchitem title='" & x.title & "' url='" & x.url & "'>"

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * $: Overload do método que transforma o objeto em string.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc `$`(x: Information): string =
    return "<Information title='" & x.title & "' url='" & x.url & "' genre='" & x.genre & "' author='" & x.author &
        "' director='" & x.director & "' company='" & x.company & "' lastEpisode='" & x.lastEpisode & "' year='" & x.year & "'>"

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * $: Overload do método que transforma o objeto em string.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc `$`(x: Episode): string =
    return "<Episode title='" & x.title & "' url='" & x.url & "' image='" & x.image & "' duration='" & x.duration.format("mm:ss") & "'>"

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * Search: Busca por um determinado anime no site.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc search(tag: string): seq[SearchItem] =
    result = @[]
    let url = "http://www.superanimes.com/anime?&letra=" & tag
    var client = newHttpClient()
    var stream = newStringStream(client.getContent(url))
    
    let html: Xmlnode = parseHtml(stream)
    for node in html.findAll("div"):
        if node.attr("class") != "boxLista2Nome" or node.child("a") == nil:
            continue
        if node.child("a")[0].rawtag == "h2":
            var item = SearchItem(title: node[0][0].innerText, url: node[0].attr("href"))
            result.add(item)

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * getEpisode: Obtém o endereço do arquivo do episódio.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc getEpisodes(item: SearchItem, pageIndex: int): seq[Episode] =
    #[var page: int = (index div 20) + 1
    var localIndex: int  = (index mod 20) + 1
    var fullUrl: string = item.url & "?&pagina=" & intToStr(page)]#
    result = @[]

    var url = item.url & "?&pagina=" & intToStr(pageIndex)
    var client = newHttpClient()
    var stream = newStringStream(client.getContent(url))

    let html: XmlNode = parseHtml(stream)
    for node in html.findAll("div"):
        if node.attr("class") != "epsBox" or node.child("div").attr("class") != "epsBoxImg": continue
        var divs: seq[XmlNode] = @[]
        node.findAll("div", divs)

        let a = divs[0].child("a")
        let duration = parse(divs[0].child("div").innerText, "mm:ss")
        let url = a.attr("href")
        let img = a.child("img").attr("src")
        let title = divs[2].child("h3").innerText

        if divs[2].attr("class") != "epsBoxSobre": continue
        result.add Episode(duration: duration, url: url, title: title, image: img)

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# * loadAnimeInfo: Obtém a lista de episódios.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc loadAnimeInfo(item: SearchItem): Information =
    result = Information()
    var client = newHttpClient()
    var stream = newStringStream(client.getContent(item.url))

    let html: XmlNode = parseHtml(stream)
    for node in html.findAll("div"):
        if node.attr("class") != "boxAnimeSobre": continue
        var fields: seq[XmlNode] = @[]
        node.findAll("div", fields)

        result = Information()
        result.title = item.title
        result.url = item.url
        result.genre = fields[1].innerText.replace("Genero: ", "")
        result.author = fields[2].innerText.replace("Autor: ", "")
        result.director = fields[3].innerText.replace("Direção: ", "")
        result.company = fields[4].innerText.replace("Estudio: ", "")
        result.lastEpisode = replace(fields[7].innerText.replace("Episódios: ", ""), re"\s+")
        result.year = fields[12].innerText.replace("Ano: ", "")
        result.pages =
            if parseInt(result.lastEpisode) < 20: 1
            else: parseInt(result.lastEpisode) div 20

let results: seq[SearchItem] = search("Naruto")
echo results[0].loadAnimeInfo().pages
discard results[0].getEpisodes(1)
