classdef pipeData_test < matlab.unittest.TestCase
    
    properties
        testpipename = 'pipe_test';
    end
    
    methods(Test)
        function test_unique_client_pipe_name(testCase)
            p = pipeDataClient;
            q = pipeDataClient;
            assert(~strcmp(p.pipeName,q.pipeName),'Randomly created client pipe names are identical');
        end
        
        function test_unique_server_pipe_name(testCase)
            p = pipeDataServer;
            q = pipeDataServer;
            assert(~strcmp(p.pipeName,q.pipeName),'Randomly created server pipe names are identical');
        end
        
        function test_server_connection_timeout(testCase)
            p = pipeDataServer;
            p.timeOutInMs = 12000;
            atic = tic;
            p.WaitForConnection;
            assert(abs(p.timeOutInMs/1000-toc(atic))<1, 'Server connection timeout is not within 1 second of measured timeout')
            assert(~p.IsConnected, 'Server connection timed out but IsConnected flag is true');
        end
        
        function test_client_connection_timeout(testCase)
            p = pipeDataClient;
            p.timeOutInMs = 12000;
            atic = tic;
            p.Connect;
            assert(abs(p.timeOutInMs/1000-toc(atic))<1, 'Client connection timeout is not within 1 second of measured timeout')
            assert(~p.IsConnected, 'Client connection timed out but IsConnected flag is true');
        end
        
        function test_data_integrity(testCase)
            %  1.  orig:   server 'out' waits
            %  2.  new:    client 'out' connects
            %  3.  new:    server 'in' waits
            %  4.  orig:   client 'in' waits
            %  5   check all connections
            %  6.  orig:   send data via 'out'
            %  7.  new:    receive data via 'out'
            %  8.  new:    send data via 'in'
            %  9.  orig:   receive data via 'in'
            % 10.  verify data
            
            origServer = pipeDataServer;
            out = origServer.pipeName;
            origClient = pipeDataClient;
            in = origClient.pipeName;
            origServer.timeOutInMs = 30000;
            data = rand(100);
            
            % this string cannot have spaces!
            runstr  = ['newServer=pipeDataServer(''' in ''');' ...
                'newClient=pipeDataClient(''' out ''');' ...
                'newClient.Connect;'...
                'newServer.WaitForConnection;' ...
                'tmp=newClient.ReceiveData;'...
                'newServer.SendData(tmp);'];
            
            % open new process and call client side
            system(['start matlab -nosplash -nodesktop -r ' runstr ';quit  -logfile logfile.log']);
            
            % queue up 'orig' side operations
            origServer.WaitForConnection;
            origClient.Connect;
            origServer.SendData(data);
            data_prime = origClient.ReceiveData;
            assert(isequal(data,data_prime),'Received data does not match sent data.')
        end
        
        function test_data_integrity_inout_direction(testCase)
            %  1.  orig:   server 'out' waits
            %  2.  new:    client 'out' connects
            %  6.  orig:   send data via 'out'
            %  7.  new:    receive data via 'out'
            %  8.  new:    send data via 'out'
            %  9.  orig:   receive data via 'out'
            % 10.  verify data
            
            origServer = pipeDataServer;
            out = origServer.pipeName;
            origServer.timeOutInMs = 30000;
            data = rand(100);
            
            % this string cannot have spaces!
            runstr= [...
                'newClient=pipeDataClient(''' out ''');'...
                'newClient.Connect;'...
                'tmp=newClient.ReceiveData;'...
                'newClient.SendData(tmp);' ];
            
            % open new process and call file
            system(['start matlab -nosplash -nodesktop -r ' runstr ';quit  -logfile logfile.log']);
            
            % queue up 'orig' side operations
            origServer.WaitForConnection;
            origServer.SendData(data);
            data_prime = origServer.ReceiveData;
            assert(isequal(data,data_prime),'Received data does not match sent data.')
        end
        
        function test_data_integrity_inout_direction_multiplebuffersize(testCase)
            % test for correct handling of large data ... i.e.
            % length(data)>length(buffer)
            % read buffer is set to divide exactly into the length of the
            % bytestream to also check that edge-case
            origServer = pipeDataServer;
            out = origServer.pipeName;
            origServer.timeOutInMs = 30000;
            data = rand(100);
            
            % this string cannot have spaces!
            runstr= [...
                'newClient=pipeDataClient(''' out ''');'...
                'newClient.readBufferSize=139;'...
                'newClient.Connect;'...
                'tmp=newClient.ReceiveData;'...
                'newClient.SendData(tmp);' ];
            
            % open new process and call file
            system(['start matlab -nosplash -nodesktop -r ' runstr ';quit  -logfile logfile.log']);
            
            % queue up 'orig' side operations
            origServer.WaitForConnection;
            origServer.SendData(data);
            data_prime = origServer.ReceiveData;
            assert(isequal(data,data_prime),'Received data does not match sent data.')
        end
        
    end
end