# Scryfall Image Downloader

A simple script that will parse the Scryfall Bulk Data JSON and download all the highest available quality card images in it.

## Requirements

Needs `jq` installed to parse JSON and GNU `parallel` to run parallel tasks

```bash
brew install jq parallel
```

# Usage

Download the "Unique Artwork" bulk data JSON file from here;

https://scryfall.com/docs/api/bulk-data

Run the script against the file

```bash
./download.sh unique-artwork-20251119100609.json
```

The script will do the following;

- extract the URL's to all the PNG images from the JSON (the `image_uris` field which tends to have the highest available quality image for each card)

- resolve the download filename for each URL

- check if we already downloaded that file in the `images` dir that will be created

- if not, download that PNG file to the `images` subdir in this dir

- save a record that we downloaded the file so that we can skip the URL filename resolution in the future

It should look like this

```
$ ./download.sh unique-artwork-20251119100609.json
Skipping: Found previously saved filename for https://cards.scryfall.io/png/front/0/0/0000419b-0bba-4488-8f7a-6194544ce91e.png?1721427487
Skipping: Found previously saved filename for https://cards.scryfall.io/png/front/0/0/0000579f-7b35-4ed3-b44c-db2a538066fe.png?1562894979
Filename not previously saved
Processing: https://cards.scryfall.io/png/front/0/2/02cdc433-a41b-4f45-b40f-3618c399e196.png?1674138620
Downloading to: /Users/tazzuu/MTG/apps/scryfall-image-downloader/images/clb-408-halsin-emerald-archdruid.png
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1563k  100 1563k    0     0  17.5M      0 --:--:-- --:--:-- --:--:-- 17.5M
Filename not previously saved
Processing: https://cards.scryfall.io/png/front/0/2/02ce7345-6a4b-4927-8d34-1c6fba6d5759.png?1686964815
Downloading to: /Users/tazzuu/MTG/apps/scryfall-image-downloader/images/ltc-117-rampaging-war-mammoth.png
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1175k  100 1175k    0     0  7959k      0 --:--:-- --:--:-- --:--:-- 7997k
```

