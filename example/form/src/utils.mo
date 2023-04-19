import Debug "mo:base/Debug";

import Mo "mo:moh";

import Router "../../../src/Router"; // replace with 'import Router "mo:web/Router";''

module {

    let format = Mo.Text.format;

    public func greet(name : Text) : Text {
        "Hello, " # name # "! ";
    };

    public func htmlPage(name : Text) : Text {
        "<html><head><title> http_request </title></head><body><h1>" # greet(name) # "</h1><br><form \"multipart/form-data\" action=\".\" >\n    <div><label for=\"fname\">First Name</label>\n    <input type=\"text\" id=\"fname\" name=\"firstname\" placeholder=\"Your name..\"></div>\n\n    <div><label for=\"lname\">Last Name</label>\n    <input type=\"text\" id=\"lname\" name=\"lastname\" placeholder=\"Your last name..\"></div>\n\n    <div><label for=\"country\">Country</label>\n    <select id=\"country\" name=\"country\">\n      <option value=\"australia\">Australia</option>\n      <option value=\"canada\">Canada</option>\n      <option value=\"usa\">USA</option>\n    </select></div>\n\n  <div><label for=\"files\">Files</label>\n <input id=\"files\" multiple type=\"file\" > \n  <input  type=\"submit\" value=\"Submit\"></div>\n  </form>\n <script>\nconst form = document.querySelector(\"form\")\n const handleSubmit = (e)=>{\n e.preventDefault() \nvar input = document.querySelector(\'input[type=\"file\"]\')\n\nvar data = new FormData(form)\ndata.append(\'file\', input.files[0])\ndata.append(\'file\', input.files[1])\ndata.append(\'duplicate-field\', \"value1\")\ndata.append(\'duplicate-field\', \"value3\")\ndata.append(\'Duplicate-field\', \"value2\")\n\nfetch(\'.\', {\n  method: \'POST\',\nheaders:{\n    \"duplicate-header\":\"john\",\n    \"Duplicate-Header\":\"fred\",\n},\n  body: data\n}).then(res=>res.text())\n\n}\n form.addEventListener(\"submit\", handleSubmit)</script></body></html>\n";
    };

    public func debugRequestParser(req : Router.Request) {
        Debug.print(format("Method ({})", [(req.method)]));
        Debug.print("\n");

        let { url; query_params; body } = req;

        Debug.print(format("URl ({})", [(url.text)]));

        Debug.print(format("Protocol ({})", [debug_show (url.protocol)]));

        Debug.print(format("Host ({})", [(url.host)]));

        Debug.print(format("Port ({})", [debug_show (url.port)]));

        Debug.print(format("Path ({})", [(url.path)]));
        Debug.print(format("Path Segments ({})", [debug_show (url.segments)]));

        for ((key, value) in query_params.entries()) {
            Debug.print(format("Query ({}: {})", [(key), (value)]));
        };

        Debug.print(format("Anchor ({})", [(url.anchor)]));

        Debug.print("\n");
        Debug.print("Headers");
        for ((key, val) in req.headers.entries()) {
            Debug.print(format("Header ({}: {})", [(key), debug_show (val)]));
        };

        Debug.print("\n");
        Debug.print("Body");

        Debug.print("Form");
        for ((name, val) in req.form_values.entries()) {
            Debug.print(format("Field ({}: {})", [(name), debug_show (val)]));
        };

        for ((name, file) in req.files.entries()){
            Debug.print(
                format(
                    "File ({}: filename: \"{}\", mime_type: \"{}\", {} bytes)",
                    [(name), (file.filename), (file.mimeType), debug_show (file.size())],
                ),
            );
        };
    };
}