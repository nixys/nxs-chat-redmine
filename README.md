# nxs-chat-redmine

## Introduction

The plugin provides additional REST API and Webhooks features required for integration Redmine with [nxs-support-bot](https://github.com/nixys/nxs-support-bot).

### Features

- Enable webhook within a Redmine to send to specified endpoint an issue updates
- Enable some additional REST API methods (such as: get user last issue, get user info with language and get plugin info)
- Support localization (with Localizable Redmine plugin)
- Compatible with Redmine 4.2+

### Who can use the tool

Any users who need to use [nxs-support-bot](https://github.com/nixys/nxs-support-bot)

## Quickstart

Compatible with [nxs-support-bot](https://github.com/nixys/nxs-support-bot):

| `nxs-chat-redmine` | [nxs-support-bot](https://github.com/nixys/nxs-support-bot) |
| --- | --- |
| v1.5 - v3.2.0 | v1.0.0 - v1.2.0 |
| v4.0.0 | v1.3.0 |

### Install

Download archive from [releases page](https://github.com/nixys/nxs-chat-redmine/releases) and unpack into `REDMINE_PATH/plugins/nxs_chat` directory. No migration is required.

After plugin has been installed you only need to [Configure](#configure) it and restart you Redmine.

### Configure

To configure `nxs-chat-redmine` plugin go to page `/settings/plugin/nxs_chat` within your Redmine website and specify settings described below:

| Option | Description |
| --- |---|
| `URL for notifications` | Host address (including protocol and port) to send a webhook from Redmine (e.g. "https://your.nxs-support-bot.com:8443")|
| `Disable SSL verification` | If your `nxs-support-bot` and Redmine both works in the local network or you do not use the SSL for Bot you need to set this option to true|
| `Token for notification endpoint` | Token to authenticate on `nxs-support-bot` for send a webhooks. This value must be the same with `secretToken` from `nxs-support-bot` [settings](https://github.com/nixys/nxs-support-bot#api-settings) |
| `Additional languages for notifications` | Select a languages you want to add to webhook messages. This option has affect only if Localizable Redmine plugin is used |

## Details

### Rest API

**`GET /users/:id/last_issue.:format`**

Returns information of last created/edited issue for user including ID and subject. If issue is not found then `issue` block will not be present in the response.

Regular users can get information only about themselves. User with admin permission can get information about any user in Redmine.

Example:
- Request:
  `GET /users/1/last_issue.json`
- Response:
  ```json
  {
      "user": {
          "id": 1,
          "issue": {
              "id": 1,
              "project": {
                  "id": 1,
                  "name": "test-project"
              },
              "subject": "Test issue"
          }
      }
  }
  ```

**`GET /users_languages.:format`**

Extends default `/users.:format` API method with adding `language` field. Only users with admin permission can use this API method.

Example:
- Request:
  `GET /users_languages.json`
- Response:
  ```json
  {
      "users": [
          {
              "id": 1,
              "login": "admin",
              "firstname": "Redmine",
              "lastname": "Admin",
              "mail": "admin@example.net",
              "created_on": "2017-10-17T16:56:53Z",
              "last_login_on": "2023-12-06T07:10:48Z",
              "custom_fields": [
                  {
                      "id": 1,
                      "name": "Telegram",
                      "value": ""
                  }
              ],
              "language": "en"
          },
      ],
      "total_count": 1,
      "offset": 0,
      "limit": 25
  }
  ```

**`GET /plugins/nxs_chat/info.:format`**

Returns current API version of this plugin.

Example:
- Request:
  `GET /plugins/nxs_chat/info.json`
- Response:
  ```json
  {
      "plugin": {
          "name": "nxs_chat",
          "api_version": "v2"
      }
  }
  ```

### Webhook

This plugin represents a two type of webhooks. In each of the case plugin will sent a POST request to a host specified in `URL for notifications`. A body content depends on webhook type. See an examples below:

- On issue create:
  ```json
  {
    "action": "issue_create",
    "data": {
      "issue": {
        "id": 3,
        "project": {
          "id": 1,
          "name": "Nixys",
          "members": [
            {
              "id": 5,
              "name": "Test user 1",
              "roles": [
                {
                  "id": 3,
                  "name": "Manager",
                  "permissions": {
                    "issues_visibility": "all",
                    "view_private_notes": true
                  }
                }
              ],
              "access": {
                "view_current_issue": true,
                "view_private_notes": true
              }
            },
            {
              "id": 6,
              "name": "Test user 3",
              "roles": [
                {
                  "id": 3,
                  "name": "Manager",
                  "permissions": {
                    "issues_visibility": "all",
                    "view_private_notes": true
                  }
                },
                {
                  "id": 4,
                  "name": "Developer",
                  "permissions": {
                    "issues_visibility": "default",
                    "view_private_notes": false
                  }
                },
                {
                  "id": 5,
                  "name": "Reporter",
                  "permissions": {
                    "issues_visibility": "default",
                    "view_private_notes": false
                  }
                }
              ],
              "access": {
                "view_current_issue": true,
                "view_private_notes": true
              }
            }
          ]
        },
        "tracker": {
          "id": 1,
          "name": {
            "default": "Bug",
            "en": "Bug",
            "ru": "Ошибка"
          }
        },
        "status": {
          "id": 1,
          "name": {
            "default": "New",
            "en": "New",
            "ru": "Новая"
          }
        },
        "priority": {
          "id": 2,
          "name": {
            "default": "Normal",
            "en": "Normal",
            "ru": "Нормальный"
          }
        },
        "author": {
          "id": 1,
          "name": "Redmine Admin"
        },
        "subject": "Test issue",
        "description": "Hello, @testuser1!",
        "start_date": "2017-09-19",
        "due_date": null,
        "done_ratio": 0,
        "is_private": false,
        "estimated_hours": null,
        "spent_hours": 0.0,
        "mentioned_users": [
          {
            "id": 5,
            "name": "Test user 1"
          }
        ],
        "custom_fields": [],
        "created_on": "2017-09-19T12:14:43Z",
        "updated_on": "2017-09-19T12:14:43Z",
        "closed_on": null,
        "attachments": [
          {
            "id": 6,
            "filename": "Test.txt",
            "filesize": 7705,
            "content_type": "",
            "description": "Example text file",
            "author": {
              "id": 1,
              "name": "Redmine Admin"
            },
            "created_on": "2017-09-19T12:14:43Z"
          },
          {
            "id": 7,
            "filename": "network.png",
            "filesize": 71745,
            "content_type": "",
            "description": "",
            "author": {
              "id": 1,
              "name": "Redmine Admin"
            },
            "created_on": "2017-09-19T12:14:43Z"
          }
        ],
        "watchers": [
        ]
      }
    }
  }
  ```

- On issue update:
  ```json
  {
    "action": "issue_edit",
    "data": {
      "issue": {
        "id": 1,
        "project": {
          "id": 1,
          "name": "Nixys",
          "members": [
            {
              "id": 5,
              "name": "Test user 1",
              "roles": [
                {
                  "id": 3,
                  "name": "Manager",
                  "permissions": {
                    "issues_visibility": "all",
                    "view_private_notes": true
                  }
                }
              ],
              "access": {
                "view_current_issue": true,
                "view_private_notes": true
              }
            },
            {
              "id": 6,
              "name": "Test user 3",
              "roles": [
                {
                  "id": 3,
                  "name": "Manager",
                  "permissions": {
                    "issues_visibility": "all",
                    "view_private_notes": true
                  }
                },
                {
                  "id": 4,
                  "name": "Developer",
                  "permissions": {
                    "issues_visibility": "default",
                    "view_private_notes": false
                  }
                },
                {
                  "id": 5,
                  "name": "Reporter",
                  "permissions": {
                    "issues_visibility": "default",
                    "view_private_notes": false
                  }
                }
              ],
              "access": {
                "view_current_issue": true,
                "view_private_notes": true
              }
            },
            {
              "id": 7,
              "name": "Test user 2",
              "roles": [
                {
                  "id": 4,
                  "name": "Developer",
                  "permissions": {
                    "issues_visibility": "default",
                    "view_private_notes": false
                  }
                }
              ],
              "permissions": {
                "view_current_issue": false,
                "view_private_notes": false
              }
            }
          ]
        },
        "tracker": {
          "id": 1,
          "name": {
            "default": "Bug",
            "en": "Bug",
            "ru": "Ошибка"
          }
        },
        "status": {
          "id": 1,
          "name": {
            "default": "New",
            "en": "New",
            "ru": "Новая"
          }
        },
        "priority": {
          "id": 2,
          "name": {
            "default": "Normal",
            "en": "Normal",
            "ru": "Нормальный"
          }
        },
        "author": {
          "id": 1,
          "name": "Redmine Admin"
        },
        "subject": "Test issue",
        "description": "",
        "start_date": "2017-09-19",
        "due_date": null,
        "done_ratio": 0,
        "is_private": false,
        "estimated_hours": null,
        "spent_hours": 0.0,
        "created_on": "2017-09-19T12:05:12Z",
        "updated_on": "2017-09-19T12:43:44Z",
        "closed_on": null,
        "attachments": [],
        "journals": [
          {
            "id": 3,
            "indice": 1,
            "user": {
              "id": 5,
              "name": "Test user 1"
            },
            "notes": "Hello, @admin!",
            "private_notes": false,
            "created_on": "2017-09-19T12:43:44Z",
            "details": [
            ],
            "mentioned_users": [
              {
                "id": 1,
                "name": "Redmine Admin"
              }
            ]
          }
        ],
        "watchers": [
          {
            "id": 5,
            "name": "Test user 1"
          }
        ]
      }
    }
  }
  ```

## Feedback

For support and feedback please contact me:
- [Issues](https://github.com/nixys/nxs-chat-redmine/issues)
- Telegram: [@borisershov](https://t.me/borisershov)
- E-mail: b.ershov@nixys.io

## License

nxs-chat-redmine is released under the [GNU General Public License v2 (GPLv2)](LICENSE).
