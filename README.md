# phoenix_rails
Rails client for sending events to Phoenix server. The idea of the project is to have an interface from a rails app that can talk to a phoenix app for pushing events to realtime.

                  HTTP/HTTPS
Rails app  ------------------------ Phoenix app
    |              Events               |
    |                                   |
    |                                   | Web socket
    |                                   |
    |                                   |
    |-------------- Client --------------
 

Update In Progress
