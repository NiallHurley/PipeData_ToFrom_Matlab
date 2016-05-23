classdef pipeDataClient < handle
    % A class which connects to the class pipeDataServer and creates a
    % bi-directional pipe to transmit data from one matlab process to
    % another. 
    %
    % Only significant difference between Client and Server is that Client
    % connects, ... Server waits for client to connect
    %
    % For Examples see corresponding unit test
    %
    % For further information see:
    %   * https://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeserverstream(v=vs.110).aspx
    %   * https://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeclientstream(v=vs.110).aspx
    
    % NH 20160422
    properties (SetAccess = protected)
        pipeName                 % name of pipe - needed to connect 
        IsConnected              % boolean status of pipe connection
    end
    properties (Hidden = true)
        pipeStream                % NamedPipeClientStream object
    end
    properties (SetAccess = public)
        verbose = false;          % print extra info
        timeOutInMs  = 10000;     % default is 10s
        readBufferSize = 1024^2;  % default is 1MB
    end
    
    methods
        function this = pipeDataClient(pipeName)
            % Constructor - creates instance of class and constructs the pipe
            % optional pipeName argument - will be set to a random string
            % if undefined. Pipe Direction is InOut i.e. can receive and
            % send. 
            if nargin<1
                this.pipeName = randomNameGenerator(16);
            else
                this.pipeName = pipeName;
            end
            debugPrint(this,['Pipe name: ' this.pipeName])
            
            NET.addAssembly('System.Core');
            % client pipeStream object is opened in InOut mode
            this.pipeStream = System.IO.Pipes.NamedPipeClientStream('.', ...
                this.pipeName,...
                System.IO.Pipes.PipeDirection.InOut);
            debugPrint(this,'Client pipe')
        end
        
        function this = Connect(this)
            % connect to the server class (uses timeout) 
            debugPrint(this,'Connecting pipe.')
            try
                this.pipeStream.Connect(this.timeOutInMs);
            catch
                debugPrint(this,'Pipe connect timeout.')
            end
            this.IsConnected = this.pipeStream.IsConnected;
            debugPrint(this,['Pipe connected = ' num2str(this.IsConnected)] )
        end
        
        function this = SendData(this,dataToStream)
            % Send data back to server using
            % {pipeDataClient}.SendData(rand(1:10)); this is possible as
            % client pipeStream object is opened in InOut mode
            % - initially sends the length of the byteStream of
            % dataToStream to notify client of expected length. 
            if ~this.pipeStream.IsConnected
                throw(MException([mfilename ':SendDataError'],'Pipe is not connected.'));
            end
            tmp= getByteStreamFromArray(dataToStream);
             % header is the length of the byteStream - this is to notify
             % the client so the client can know when to stop reading
            header = getByteStreamFromArray(numel(tmp));
            debugPrint(this,'notify client of length of data ...')
            this.pipeStream.Write(header,0,length(header))
            debugPrint(this,'finished notifying.')            
            
            debugPrint(this,'begin send...')
            this.pipeStream.Write(tmp,0,length(tmp))
            debugPrint(this,'finished send.')
        end
        
        function received_data = ReceiveData(this)
            % receive data via pipe (decodes serialized byte stream and
            % reconstitutes to originally sent format) 
            headerbufferLength = 256;
            headerbuffer = NET.createArray('System.Byte',headerbufferLength);
            buffer = NET.createArray('System.Byte',this.readBufferSize);
            byteStream = []; %zeros(1,buffer.Length,'uint8');            
            if ~this.IsConnected
                debugPrint(this,'Pipe connecting...')
                this.pipeStream.Connect(this.timeOutInMs)
            end       
            
            % process header (which should just be the length of the data)
            debugPrint(this,'Reading header...')
            headerbufferbytecount = this.pipeStream.Read(headerbuffer,0,headerbufferLength);
            headerbufferMatlabType = headerbuffer.uint8;
            assert(headerbufferbytecount<headerbufferLength,'header buffer received is too long');
            headerContent = getArrayFromByteStream(headerbufferMatlabType(1:headerbufferbytecount));
            debugPrint(this,['Header recieved - data will be ' num2str(headerContent) ' bytes long'])
            
            atic = tic;
            debugPrint(this,'Reading dataStream...')
            while true
                bufferbytecount = this.pipeStream.Read(buffer,0,this.readBufferSize);
                bufferMatlabType = buffer.uint8;
                byteStream = [byteStream bufferMatlabType(1:bufferbytecount)];       %#ok<AGROW>
                if length(byteStream)>=headerContent
                    break
                end
            end
            debugPrint(this,[ num2str(length(byteStream)) ' bytes received in ' num2str(toc(atic),'%.2f') ' seconds'])
            received_data = getArrayFromByteStream(byteStream);
        end
        
        function Close(this)
            % Close the pipeStream object
            this.pipeStream.Close
            debugPrint(this,'Pipe Closed');
        end
        
        function debugPrint(this,messageString)
            % if this flag is set to true then extra information is
            % displayed in the command window (usually for debugging)
            if this.verbose
                disp([datestr(now,'HH:MM:SS') ' DEBUG: ' mfilename ': ' messageString]);
            end
        end
    end
end




function randString = randomNameGenerator(randStringLength)
if nargin<1
    randStringLength = 12;
end
symbols = ['a':'z' 'A':'Z' '0':'9'];
rng('shuffle')
nums = randi(numel(symbols),[1 randStringLength]);
randString = [datestr(now,'yyyymmdd_HHMMSS_') symbols(nums)];
end