// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerinax/sfdc;
import ballerina/io;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
        baseUrl: "<BASE_URL>",
        clientConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    };

    // Create Salesforce client.
    sfdc:BaseClient baseClient = checkpanic new(sfConfig);

    string batchId = "";
    string jsonContactsFilePath = "resources/contacts.json";

    sfdc:BulkJob|error insertJob = baseClient->creatJob("insert", "Contact", "JSON");

    if (insertJob is sfdc:BulkJob){
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(jsonContactsFilePath);
        if (rbc is io:ReadableByteChannel){
            error|sfdc:BatchInfo batch = insertJob->addBatch(<@untainted>rbc);
            if (batch is sfdc:BatchInfo) {
                string message = batch.id.length() > 0 ? "Batch Added Successfully" :"Failed to add the Batch";
                batchId = batch.id;
                log:print(message + " : " + message + " " + batchId);
            } else {
                log:printError(batch.message());
            }
        }
        else{
            log:printError(rbc.message());
        }
        

        //get job info
        error|sfdc:JobInfo jobInfo = baseClient->getJobInfo(insertJob);
        if (jobInfo is sfdc:JobInfo) {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" :"Failed Retrieve Job Info";
            log:print(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|sfdc:BatchInfo batchInfo = insertJob->getBatchInfo(batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:print(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = insertJob->getAllBatches();
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:print(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = insertJob->getBatchRequest(batchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                string message = batchRequestArr.length() > 0 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
                log:print(message);
            } else {
                log:printError(batchRequestArr.message());
            }
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = insertJob->getBatchResult(batchId);
        if (batchResult is sfdc:Result[]) {
           string message = batchResult.length() > 0 ? "Batch Result Received Successfully" :"Failed to Retrieve Batch Result";
           log:print(message);
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(insertJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }



}
