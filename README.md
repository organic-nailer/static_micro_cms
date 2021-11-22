# static_micro_cms

It is a package that helps you create a static webpage with Jamstack using microCMS.

これは[microCMS](https://microcms.io/)を使ってJamstack構成でFlutter製のWebページを制作するのを支援するパッケージです。

## Features

When you use this package, you can create a static webpage with microCMS, a headless CMS.
It loads all api data before building an application, so there is no need to access to apis at run-time,
and no need to keep an api key in the source code. It offers more secure and faster websites.
It can also load data in CI.

## Getting started

1. Create a microCMS API in https://microcms.io/
2. Create contents and define schemas.
3. Download API schemas and put it in the project (ex. `./schemas/api-xxx-000.json`). You can get it in [API Settings].
4. Describe configurations in `pubspec.yaml` like below.

```yaml
#...
static_micro_cms:
  baseUrl: "https://[your project name].microcms.io/api/v1"
  apis:
    - endpoint: profile
      type: object
      schema: schema/api-profile-20211122080708.json
    - endpoint: news
      type: list
      schema: schema/api-news-20211121223418.json
#...
```

5. Get API key from cms console, and put it on `.env` in project root like below.

```
API_KEY=[your api key]
```

6. To load data and create type definitions, run `flutter pub run static_micro_cms`. Then `types.microcms.g.dart` and `datastore.microcms.g.dart` will be created in `/lib` folder.
7. [optional] if you don't want to upload api data, add `*.microcms.g.dart` to `.gitignore`

## Usage

After generation of the api data, you can use data with `MicroCMSDataStore.[endpoint]Data`.

### how to write configs

- `baseUrl`: (required) The base url of the api. You can find it on [API Preview] window.
- `apis.endpoint`: (required) The endpoint name of the content.  
- `apis.type`: (required) content type. "object" or "list"
- `apis.schema`: (required) schema file path.

### update only type definitions

If you update api schemas but want to avoid useless communications, you can try `flutter pub run static_micro_cms --dry`.
It updates only type definitions.

## implementation progress

- contents
  - [x] object
  - [x] list  

- types
  - [x] text
  - [x] textArea
  - [x] richEditor
  - [x] image
  - [x] date
  - [x] boolean
  - [ ] select
  - [x] number
  - [x] custom
  - [ ] repeater
    - single field type only
