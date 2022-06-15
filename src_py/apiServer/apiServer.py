from multiprocessing import Process
from transmitter import Transmitter
import globalVars as globe
from receiver import *
import time
import requests
import threading

class ApiServer():
    def __init__(self): 
        mainServerIP = globe.components.mainServerIp
        mainServerPort = globe.components.mainServerPort
        self.mainServerAddress = 'http://' + mainServerIP + ':' + mainServerPort
        
        # Starting receiver flask server process:
        print("Starting the receiver HTTP server...\n")

        self.serverThread = threading.Thread(target=initReceiver, args=())
        self.serverThread.start()
        time.sleep(1)

        self.transmitter = Transmitter(self.mainServerAddress)

        # Send the content of jsonPath to each devices:
        print("\nSending JSON paths to devices...")

        archAddress = globe.content[0][:-1]
        connMapAddress = globe.content[1][:-1]
        data = archAddress + '#' + connMapAddress

        for ip in globe.components.devicesIp:
            address = f'http://{ip}:8484/updateJsonPath' # f for format

            response = requests.post(address, data, timeout = 10)
            if globe.jupyterFlag == 0:
              print(response.ok, response.status_code)

        time.sleep(1)

    def getWorkersList(self):
        return globe.components.toString('w')
    
    def getRoutersList(self):
        return globe.components.toString('r')
    
    def getSourcesList(self):
        return globe.components.toString('s')
        
    def getTransmitter(self):
        return self.transmitter

    def stopServer(self):
        receiver.stop()
        return True

    def getQueueData(self):
        received = False
        
        while not received:
            if not multiProcQueue.empty():
                print("~New result has been created successfully~")
                expResults = multiProcQueue.get() # Get the new result out of the queue
                received = True
            time.sleep(0.1)

            return expResults
   
    def train(self):
        self.transmitter.train()
        expResults = self.getQueueData()
        print('Training - Finished\n')
        return expResults

    def predict(self):
        self.transmitter.predict()
        expResults = self.getQueueData()
        print('Prediction - Finished\n')
        return expResults
    
    def statistics(self):
        self.transmitter.statistics()

if __name__ == "__main__":
    apiServerInst = ApiServer()
    apiServerInst.train()
    #print(globe.lossMaps)
    apiServerInst.predict()
    #apiServerInst.statistics()
    #transmitterInst = apiServerInst.getTransmitter()
    #transmitterInst.testPost()

'''
 def exitHandler(self):
        print("\nServer shutting down")
        exitReq = requests.get(self.mainServerAddress + '/shutdown')
        if exitReq.ok:
            exit(0)
        else:
            print("Server shutdown failed")
            exit(1)
'''
'''
        #serverState = None

        #while(serverState != SERVER_DONE):
         #  if not serverState:
          #    if it is integer: 
           #         serverState = self.managerQueue.get()

                #TODO add timeout mechanism (if mainServer falls kill after X seconds)
            #sleep(5)
        # wait on Queue
        #return ack.json() 
'''
