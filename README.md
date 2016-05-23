# PipeData_ToFrom_Matlab
Matlab Classes (Server and Client) for passing data from one instance of Matlab to another by creating bi-directional pipe to transmit data from one matlab process to another.
(Uses .NET so Windows only!). No special toolboxes required.

Only significant difference between Client and Server is that Client connects, whereas the Server waits for the Client to connect.

## Files
- **pipeDataClient.m** - Client Class
- **pipeDataServer.m** - Server Class
- **pipeData_test.m**  - Unit test

## How it works
The file uses the .NET NamedPipe Client and Server Stream to create a bi-directional pipe from one instance of Matlab to another. The data to be passed is serialized on the sending side and deserialized on the receiving side.


## Examples
 For usage examples see the unit test.


## Unit test
Unit Test for pipeDataServer and pipeDataClient including a data-integrity test which creates a pipe, sends data, receives that data and verifies that is matches the sent data.
   Run using runtest command
   e.g.
     runtest(path_to_folder_containing_unit_test)


## Help
As with all Matlab files, at the prompt type:
```
help <command>
```
or
```
doc <command>
```

## Further information:
- https://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeserverstream(v=vs.110).aspx
- https://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeclientstream(v=vs.110).aspx
