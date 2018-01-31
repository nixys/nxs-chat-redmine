# nxs-chat-redmine

This plugin provides additional REST API and Webhooks features required for integration with Telegram bot [nxs-chat-srv](https://github.com/nixys/nxs-chat-srv).

## Installation

Download archive from releases page and unpack into `REDMINE_PATH/plugins/nxs_chat` directory.

No migration is required.

## Configuration

You can specify URL for webhooks on the plugin settings page.

## Features overview

This plugin provides the following features:

* **REST API**

  Method to get last created or edited issue for user.

  URL: `/users/:id/last_issue.:format`

  Method that extends default `/users.:format` API by adding language field.

  URL: `/users_languages.:format`

* **Webhooks**

  Send notifications for new and edited issues via POST request to a specific URL.

## REST API

### `/users/:id/last_issue.:format`

#### GET

Return information of last created/edited issue for user including ID and subject. If issue is not found then `issue` block will not be on response.

Regular users can receive information only about themselves. Redmine administrator can see information about any user.

* Example request:

  ```
  GET /users/1/last_issue.xml
  ```

* Response:

  ```xml
  <user>
    <id>1</id>
    <issue>
      <id>3</id>
      <project id="2" name="Nixys"/>
      <subject>Test issue</subject>
    </issue>
  </user>
  ```

### `/users_languages.:format`

Extends default `/users.:format` API by adding language field. Content depends on user and Redmine settings ("default language", force default language for logged-in users").

Only Redmine administrator can use this API.

* Example request:

  ```
  GET /users_languages.xml
  ```

* Response:

  ```xml
  <users total_count="1" offset="0" limit="25" type="array">
    <user>
      <id>1</id>
      <login>admin</login>
      <firstname>Redmine</firstname>
      <lastname>Admin</lastname>
      <mail>admin@example.net</mail>
      <created_on>2017-10-17T16:56:53Z</created_on>
      <last_login_on>2018-01-31T16:33:46Z</last_login_on>
      <custom_fields type="array">
        <custom_field id="1" name="Telegram">
          <value/>
        </custom_field>
      </custom_fields>
      <language>en</language>
    </user>
  </users>
  ```

## Webhooks

Implementation based on Redmine hooks. Currently uses hooks:

* `controller_issues_new_after_save` (create issue)

* `controller_issues_edit_after_save` (edit issue: change description, add a new comment, etc)

* `model_mail_handler_receive_issue_after_save` (create issue by email)

* `model_mail_handler_receive_issue_reply_after_save` (edit issue by email)

Note that last two are added by this plugin.

### Event types

* `issue_create`

* `issue_edit`

### General event format

Body of POST request contains JSON with 2 fields:

```json
{
  "action": "TYPE",
  "data": {}
}
```

Data field contains information about issue that is similar to format of Redmine API responses.

### Examples

* `issue_create`:

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
          "name": "Bug"
        },
        "status": {
          "id": 1,
          "name": "New"
        },
        "priority": {
          "id": 2,
          "name": "Normal"
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

* `issue_edit`:

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
          "name": "Bug"
        },
        "status": {
          "id": 1,
          "name": "New"
        },
        "priority": {
          "id": 2,
          "name": "Normal"
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
            "user": {
              "id": 5,
              "name": "Test user 1"
            },
            "notes": "Message",
            "private_notes": false,
            "created_on": "2017-09-19T12:43:44Z",
            "details": [
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
