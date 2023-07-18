import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Text "mo:base/Text";

import outcall "../src/outcall";
import Response "../src/Response";

actor {

//PUBLIC METHOD
//This method sends a POST request to a URL with a free API we can test.
  public func send_http_post_request() : async Text {

    //1. SETUP ARGUMENTS FOR HTTP GET request

    // 1.1 Setup the URL and its query parameters
    // let host : Text = "en8d7aepyq2ko.x.pipedream.net";
    let url = "https://en8d7aepyq2ko.x.pipedream.net/";

    // 1.2 Setup the data to send in the body of the request
    type Data = {
        name : Text;
        force_sensitive : Bool;
    };

    // 1.3 Setup the keys of the record to send in the body of the request
    let DataKeys = ["name", "force_sensitive"];
    
    let data : Data = {
        name = "Grogu";
        force_sensitive = true;
    };

    // 1.4 Convert the Motoko data type into a candid blob
    let data_as_candid = to_candid(data); 
    
    let http_request = outcall.post(url)
        // Pass your Motoko data type directly into the body as a JSON string
        // 1. Serialize the Motoko data type into a candid blob using 'to_candid()'
        // 2. Pass the candid blob and the record keys to .json()
        .json(data_as_candid, DataKeys)

        // 2.2 enter headers for the system http_request call
        .header("User-Agent", "http_post_sample")
        .header("Idempotency-Key", Nat.toText(Int.abs(Time.now()))) // this key is generated automatically 
        // .header("Content-Type", "application/json") // this is set automatically when using .json()

        //3. ADD CYCLES TO PAY FOR HTTP REQUEST

        //IC management canister will make the HTTP request so it needs cycles
        //See: https://internetcomputer.org/docs/current/motoko/main/cycles
        
        //The way Cycles.add() works is that it adds those cycles to the next asynchronous call
        //See: https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-http_request
        .cycles(220_131_200_000); //minimum cycles needed to pass the CI tests. Cycles needed will vary on many things size of http response, subnetc, etc...).


    //4. MAKE HTTPS REQUEST AND WAIT FOR RESPONSE
    let canonical_response = await* http_request.send_request();

    //5 Create a Response object from the canonical response for additional utility functions
    let response = Response.fromCanisterHttp(canonical_response);
    
    //5.1 Use utility functions in the Response object to decode the response body
    let decoded_text = switch(response.text()){
        case (?text) { text };
        case (null) { "No value returned" };
    };

    //6. RETURN RESPONSE OF THE BODY
    let response_url: Text = "https://public.requestbin.com/r/en8d7aepyq2ko/";
    let result: Text = decoded_text # ". See more info of the request sent at at: " # response_url;
    result
  };
};