'use strict'

var cloud_configs = {
  "clouds":[
    {
      "keystoneHostname":"iu.jetstream-cloud.org",
      "friendlyName":"Jetstream1",
      "friendlySubName":"IU",
      "userAppProxy":"proxy-j7m-iu.exosphere.app",
      "imageExcludeFilter":{
        "filterKey":"atmo_image_include",
        "filterValue":"true"
      },
      "featuredImageNamePrefix":"JS-API-Featured",
      "instanceTypes":[
        {
          "friendlyName":"Ubuntu",
          "description":"- Wide compatibility with community software packages\n\n- Good choice for new users",
          "logo":"assets/img/ubuntu.svg",
          "versions":[
            {
              "friendlyName":"20.04 (latest)",
              "isPrimary":true,
              "imageFilters":{
                "uuid":"f0d43d1c-c022-4079-812c-3dd3dbee45cf"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"20.04 with GPU",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-Ubuntu20-NVIDIA-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":[
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "30",
                "31"
              ]
            },
            {
              "friendlyName":"18.04",
              "isPrimary":false,
              "imageFilters":{
                "uuid":"2f286590-357b-4ee6-9879-59f5f232507a"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"18.04 with MATLAB",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-Ubuntu18-MATLAB-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        },
        {
          "friendlyName":"Red Hat-like",
          "description":"- Based on Red Hat Enterprise Linux (RHEL)\n\n- Compatible with RPM-based software",
          "logo":"assets/img/hat-fedora.svg",
          "versions":[
            {
              "friendlyName":"CentOS 8",
              "isPrimary":true,
              "imageFilters":{
                "uuid":"db2f462d-81a4-4702-99b8-49771ad0fa1f"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"AlmaLinux 8",
              "isPrimary":false,
              "imageFilters":{
                "uuid":"60ab9277-28a4-42e4-b33d-2b911d6290cc"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"Rocky Linux 8",
              "isPrimary":false,
              "imageFilters":{
                "uuid":"d4b66a94-177f-4e5b-9ab3-b7725efcdba1"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"CentOS 7",
              "isPrimary":false,
              "imageFilters":{
                "uuid":"0a6c9ae5-deaf-4f0b-b66b-4cc36fea021e"
              },
              "restrictFlavorIds":[
                "10",
                "101",
                "102",
                "103",
                "104",
                "106",
                "14",
                "15",
                "16",
                "18",
                "19",
                "1908387c-eb82-4ee3-9bd6-1541a431c323",
                "2",
                "20",
                "21",
                "22",
                "23",
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "3",
                "30",
                "31",
                "4",
                "5",
                "6",
                "9e4f43f5-a622-4901-ae05-dbbfaec24ae0"
              ]
            },
            {
              "friendlyName":"CentOS 7 with GPU",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-CentOS7-NVIDIA-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":[
                "24",
                "25",
                "26",
                "27",
                "28",
                "29",
                "30",
                "31"
              ]
            },
            {
              "friendlyName":"CentOS 7 with Intel compiler",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-CentOS7-Intel-Developer-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        }
      ],
      "flavorGroups":[]
    },
    {
      "keystoneHostname":"tacc.jetstream-cloud.org",
      "friendlyName":"Jetstream1",
      "friendlySubName":"TACC",
      "userAppProxy":"proxy-j7m-tacc.exosphere.app",
      "imageExcludeFilter":{
        "filterKey":"atmo_image_include",
        "filterValue":"true"
      },
      "featuredImageNamePrefix":"JS-API-Featured",
      "instanceTypes":[
        {
          "friendlyName":"Ubuntu",
          "description":"- Wide compatibility with community software packages\n\n- Good choice for new users",
          "logo":"assets/img/ubuntu.svg",
          "versions":[
            {
              "friendlyName":"20.04 (latest)",
              "isPrimary":true,
              "imageFilters":{
                "name":"JS-API-Featured-Ubuntu20-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"18.04",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-Ubuntu18-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"16.04 with MATLAB",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-Ubuntu16-MATLAB-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        },
        {
          "friendlyName":"CentOS",
          "description":"- Based on Red Hat Enterprise Linux (RHEL)\n\n- Compatible with RPM-based software",
          "logo":"assets/img/hat-fedora.svg",
          "versions":[
            {
              "friendlyName":"8 (latest)",
              "isPrimary":true,
              "imageFilters":{
                "name":"JS-API-Featured-CentOS8-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"7",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-CentOS7-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"7 with Intel compiler",
              "isPrimary":false,
              "imageFilters":{
                "name":"JS-API-Featured-CentOS7-Intel-Developer-Latest",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        }
      ],
      "flavorGroups":[]
    },
    {
      "keystoneHostname":"js2.jetstream-cloud.org",
      "friendlyName":"Jetstream2",
      "friendlySubName":null,
      "userAppProxy":"proxy-js2-iu.exosphere.app",
      "imageExcludeFilter":null,
      "featuredImageNamePrefix":"Featured-",
      "instanceTypes":[
        {
          "friendlyName":"Ubuntu",
          "description":"- Wide compatibility with community software packages\n\n- Good choice for new users",
          "logo":"assets/img/ubuntu.svg",
          "versions":[
            {
              "friendlyName":"20.04 (latest)",
              "isPrimary":true,
              "imageFilters":{
                "name":"Featured-Ubuntu20",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"18.04",
              "isPrimary":false,
              "imageFilters":{
                "name":"Featured-Ubuntu18",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        },
        {
          "friendlyName":"Red Hat-like",
          "description":"- Based on Red Hat Enterprise Linux (RHEL)\n\n- Compatible with RPM-based software",
          "logo":"assets/img/hat-fedora.svg",
          "versions":[
            {
              "friendlyName":"Rocky Linux 8",
              "isPrimary":true,
              "imageFilters":{
                "name":"Featured-RockyLinux8",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"AlmaLinux 8",
              "isPrimary":false,
              "imageFilters":{
                "name":"Featured-AlmaLinux8",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            },
            {
              "friendlyName":"CentOS 7",
              "isPrimary":false,
              "imageFilters":{
                "name":"Featured-CentOS7",
                "visibility":"public"
              },
              "restrictFlavorIds":null
            }
          ]
        }
      ],
      "flavorGroups":[
        {
          "matchOn":"m3\..*",
          "title":"General-purpose",
          "description":null
        },
        {
          "matchOn":"r3\..*",
          "title":"Large-memory",
          "description":"These have lots of RAM."
        },
        {
          "matchOn":"g3\..*",
          "title":"GPU",
          "description":"These have a graphics processing unit."
        }
      ]
    },
    {
      "keystoneHostname":"keystone.rc.nectar.org.au",
      "friendlyName":"Nectar Cloud",
      "friendlySubName":null,
      "userAppProxy":null,
      "imageExcludeFilter":null,
      "featuredImageNamePrefix":null,
      "instanceTypes":[],
      "flavorGroups":[]
    }
  ]
}
