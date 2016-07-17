defmodule BbbNetworkAndSerial do
  use Application
  
  alias Nerves.Networking
  
  @interface :eth0
  
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    
    unless :os.type == {:unix, :darwin} do
      {:ok, _} = Networking.setup @interface
    end
    
    IO.puts "Testing Nervers UART now..."
    setup_serial()

    # Define workers and child supervisors to be supervised
    children = [
      # worker(BbbNetworkAndSerial.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BbbNetworkAndSerial.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  
  # Setup and initialize the serial port 
  def setup_serial() do
  
    serial_ports = Nerves.UART.enumerate
    IO.puts "Serial ports found:"
    IO.puts Map.keys(serial_ports)
    
    if Map.has_key?(serial_ports, "ttyS0") do
      {:ok, pid1} = Nerves.UART.start_link
      Nerves.UART.open(pid1, "ttyS0", speed: 115200, active: false)
      pid1
    end

    if Map.has_key?(serial_ports, "ttyACM0") do
      {:ok, pid2} = Nerves.UART.start_link
      Nerves.UART.open(pid2, "ttyACM0", speed: 19200, active: false)
      Nerves.UART.write(pid2, "\r\n")
      Nerves.UART.write(pid2, "USB\r\n")
      read_serial(pid1, pid2)
    end
  end
  
  
  def read_serial(pid1, pid2) do
    io_result = Nerves.UART.read(pid2, 60000)
    list_result = Tuple.to_list(io_result)
    string_result = Enum.at(list_result, 1)
    Nerves.UART.write(pid1, string_result)
    read_serial(pid1, pid2)
  end
  

end
