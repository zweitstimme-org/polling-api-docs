// #set document(title: "API Documentation")
// #set page(
//   paper: "a4",
//   margin: (x: 2cm, y: 2cm),
// )
// #set text(size: 10pt)

#let spec = json("openapi.json")

#let get-or(obj, key, default) = {
  if key in obj {
    obj.at(key)
  } else {
    default
  }
}

#let methods = (
  "get",
  "post",
  "put",
  "patch",
  "delete",
  "options",
  "head",
)

= #spec.info.title

#if "description" in spec.info [
  #spec.info.description
]

*Version:* `#spec.info.version`

#if "servers" in spec [
  == Servers

  #for server in spec.servers [
    - `#server.url`
    #if "description" in server [
      — #server.description
    ]
  ]
]

== Endpoints

#for path in spec.paths.keys().sorted() {
  let path-item = spec.paths.at(path)

  for method in methods {
    if method in path-item {
      let op = path-item.at(method)

      pagebreak(weak: true)

      `#upper(method)`
      path

      if "summary" in op [
        *Summary:* #op.summary
      ]

      if "description" in op [
        #op.description
      ]

      if "operationId" in op [
        *Operation ID:* `#op.operationId`
      ]

      if "tags" in op [
        *Tags:* #op.tags.join(", ")
      ]

      if "parameters" in op [
        ==== Parameters

        #table(
          columns: (1.4fr, 1fr, 1fr, 4fr),
          inset: 6pt,
          stroke: 0.5pt,
          [*Name*],
          [*In*],
          [*Required*],
          [*Description*],
          ..op
            .parameters
            .map(param => (
              [`#get-or(param, "name", "")`],
              [`#get-or(param, "in", "")`],
              [#if get-or(param, "required", false) { "yes" } else { "no" }],
              [#get-or(param, "description", "")],
            ))
            .flatten(),
        )
      ]

      if "requestBody" in op [
        ==== Request body

        #let body = op.requestBody

        #if "description" in body [
          #body.description
        ]

        #if "required" in body [
          *Required:* #if body.required { "yes" } else { "no" }
        ]

        #if "content" in body [
          *Content types:*

          #for media-type in body.content.keys().sorted() [
            - `#media-type`
          ]
        ]
      ]

      if "responses" in op [
        ==== Responses

        #table(
          columns: (1fr, 5fr),
          inset: 6pt,
          stroke: 0.5pt,
          [*Status*],
          [*Description*],
          ..op
            .responses
            .keys()
            .sorted()
            .map(code => {
              let response = op.responses.at(code)
              (
                [`#code`],
                [#get-or(response, "description", "")],
              )
            })
            .flatten(),
        )
      ]
    }
  }
}
