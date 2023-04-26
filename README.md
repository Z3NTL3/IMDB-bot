# IMDB-bot
Parallel, efficient and rapid IMDB bot to extract IMDB meta in JSON format from the series/films list given at once

``list.txt`` should contain the IDs of the film/serie. Each line should represent one ID.

### Example data save:
```js
{
    "title": "The Flash",
    "description": "Barry Allen uses his super speed to change the past, but his attempt to save his family creates a world without super heroes, forcing him to race for his life in order to save the future.",
    "popularity": "115",
    "rating": "7.8",
    "genres": [
        "Action",
        "Adventure",
        "Fantasy"
    ]
}
```

### Envs
- ``http_proxy`` -> if set uses this proxy
- ``https_proxy`` -> if set uses this proxy
- ``ALEXA_PX_TIMEOUT`` -> if set uses this timeout

# Requirements
``nimble install nimquery``

### Compile
``nim c -d:ssl -d:release app.nim``
