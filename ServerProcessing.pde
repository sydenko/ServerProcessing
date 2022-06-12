import processing.net.*; //<>//
import java.util.Map;


Server webServer;

Request rq;  // И создаём объекты для обработки запросов клиентов (rq).  123 123 123
Response rs; // И создаём объекты для обработки ответов нашего сервера (rs).

void setup() {
  size(400, 400);

  // Create a server listening on port 8080 for client requests
  webServer = new Server(this, 8080);
}

class Request {
  HashMap<String, String> headers = new HashMap<String, String>();
  String request;
  String[] requestArray;
  String[] firstLine;
  String method;
  String route;
  Boolean valid = false;
  Request(String request_) {
    request = request_;
  }
  void parseIt() {
    requestArray = split(request, "\r\n"); //Split intial request
    firstLine = split(requestArray[0], ' '); //Split the first line on spaces to find method and route
    method = firstLine[0];
    route = firstLine[1];
    for (int i=1; i<requestArray.length; i++) {
      String keyval[] = split(requestArray[i], ": "); //Split around the headers parts
      if (keyval.length == 2) { //This catches blank lines, etc
        headers.put(keyval[0], keyval[1]);
        valid = true;  //if there are at least 2 parts to one of the headers, then its valid...
      }
    }
  }
}
class Response { //Note: didn't use a hashmap for this, so the type is slightly different
  int http_status;
  String status = "HTTP/1.1 ";
  String response;
  String type;
  byte body[] = loadBytes(path);
  Response() {
    http_status = 200; //default
    response = "HTTP/1.1 ";
    type = "text/html"; //default
  }
  String sendIt() { //Append all the header parts
    response += str(http_status);
    if (http_status == 200) {
      response += " OK";
    } else if (http_status == 404) {
      response += " Not Found 1";
    } else if (http_status == 500) {
      response += " Server Error";
    }
    response += "\r\n";
    response += "Content-Type: " + type + "\r\n\r\n";
    return response;
  }
}
String path = "";
void draw() {
  // If there is an avilable client request
  Client c = webServer.available();
  if (c != null && c.active()) {

    // Read in the request from the client and then create a blank response object

    String request_string = c.readString();
    rq = new Request(request_string);
    rs = new Response();
    rq.parseIt();

    // If the request is valid HTTP and is requesting a file
    if (rq.valid && rq.method.equals("GET")) {

      // Remove double dots to prevent the client from accessing files outside of the public directory
      String sanitized_route = rq.route.replaceAll("\\.\\.", "");

      // On windows switch the forward / to back \
      if (System.getProperty("os.name").equals("Windows 8.1")) {
        sanitized_route = sanitized_route.replaceAll("\\/", "\\\\");
      }

      // Assemble the path of the local file (in public) based on the requested route
      path = sketchPath("") + "public" + sanitized_route;

      println("yes");


      // If the file exists read it into the body of the request
      File f = new File(path);
      if (f.exists() && !f.isDirectory()) {
        rs.body = loadBytes(path);
        if (match(path, "\\.html$") != null) {
          rs.type = "text/html";
        } else if (match(path, "\\.css$") != null) {
          rs.type = "text/css";
        } else if (match(path, "\\.jpg$") != null) {
          rs.type = "image/jpeg";
        }
      } else if (f.isDirectory() && new File(path + "index.html").exists()) { // If a directory is accessed load it's index.html file by default
        rs.body = loadBytes(path + "index.html");
        rs.type = "text/html";
      } else {
        rs.http_status = 404;
        rs.body = "Not found.2".getBytes();
      }
    } else {
      rs.http_status = 500;
    }
    String head = rs.sendIt();
    //Log the response
    println(" <= " + join(split(head, "\r\n"), " "));

    //Write back the response to the client
    c.write(head);
    c.write(rs.body);
    //Close the connection to the client
    c.stop();
  }
}
