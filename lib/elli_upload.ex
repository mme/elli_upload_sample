defmodule Elli.Upload do
  use Application.Behaviour
  
  def start(_type, _args) do
    :elli.start_link [callback: Elli.UploadHandler, port: 3000]
  end

end

defrecord :req, Record.extract(:req, from: "deps/elli/include/elli.hrl")

defmodule Elli.UploadHandler do
  

  @behaviour :elli_handler
  
  def init(req, _args) do
    if is_upload(req) do
      {:ok, :handover}
    else
      :ignore
    end
    
  end
  
  def is_upload(req) do
    case {:elli_request.path(req), :elli_request.method(req), :elli_request.get_header("Content-Type", req) } do
      {["upload"], :POST, <<"multipart/form-data;", _rest::binary>>}  -> 
        true
      {_, _, _} -> 
        false
    end
  end
  
  def handle(req, _args) do
    if is_upload(req) do
      handle_upload(req)
    else
      :ignore
    end
  end
  
  def send_response(req,status,body) do
    :elli_http.send_response(req, status, [{"Connection", "close"}, {"Content-Length", byte_size(body)}], body)
  end
  
  def handle_upload(req) do
    content_length = binary_to_integer(:elli_request.get_header("Content-Length", req))
    
    case :elli_request.get_header("Content-Type", req) do
      <<"multipart/form-data; boundary=", boundary::binary>> -> 
        
        parser = :erlmultipart.new(boundary, :erlmultipart.file_handler(&1, &2, &3) , 12345)
        r = :req.new req
        
        case receive_upload(parser,r.socket,content_length) do
          {:ok, result} ->  
            IO.inspect(result)
            send_response(req,200,"Ok")
          _ -> 
            send_response(req,200,"Error")
        end
        {:close, <<>>}
    end
    
  end
  
  def receive_upload(parser,socket,n) do
    read = :erlang.min(271360, n)
    
    
    case :gen_tcp.recv(socket, read) do
      
      {:ok, data} ->
        
        p = parser.(data)
        left = n - read

        case {left,p} do
          
          {0, {:ok, result}} ->
            {:ok, result}
            
          {_, {:more, parser}} ->
            receive_upload(parser,socket,left)
            
          {_,_} -> :error
          
        end
        
      error ->
        :error        
    end
  end
  

                  
  def handle_event(_, _, _) do
    :ok
  end
  
end