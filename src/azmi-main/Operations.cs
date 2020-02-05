﻿using System;
using System.IO;

using Azure.Core;
using Azure.Storage.Blobs;
using Azure.Identity;


namespace azmi_main
{
    public static class Operations
    {
        // Class defining main operations performed by azmi tool

        public static string getToken(string endpoint = "management", string identity = "")
        {
            var Cred = String.IsNullOrEmpty(identity)
                ? new ManagedIdentityCredential()
                : new ManagedIdentityCredential(identity);
            var Scope = new String[] { $"https://{endpoint}.azure.com" };
            var Request = new TokenRequestContext(Scope);
            var Token = Cred.GetToken(Request);

            return Token.Token;
        }

        public static string getBlob(string blobURL, string filePath)
        {
            // Blob naming
            // https://azmitest.blob.core.windows.net/azmi-test/tmp/azmi_integration_test_2020-01-29_04:34:16.txt
            //                    CONTAINER                    |                                                 |
            //                                                 |                      BLOB                       |

            // Download the blob to a local file
            BlobClient blobClient = null;
            try
            {                
                blobClient = new BlobClient(new Uri(blobURL), new ManagedIdentityCredential());
            } catch (Exception e)
            {
                Console.WriteLine("Can not setup blob client instance: {0}\n", e.Message);
                return "NOT OK";
            }

            Console.WriteLine("\nDownloading blob to:\n\t{0}\n", filePath);

            Azure.Storage.Blobs.Models.BlobDownloadInfo download;
            try
            {
                // Download the blob's contents
                download = blobClient.Download();
            } catch (Azure.RequestFailedException e)
            {
                Console.WriteLine("Download failed: {0}\n", e.Message);                
                return "NOT OK";
            }

            FileStream downloadFileStream = null;
            string return_value = null;
            try {
                // and save it to a file                
                downloadFileStream = File.OpenWrite(filePath);
                download.Content.CopyTo(downloadFileStream);
                downloadFileStream.Close();
                return_value = "OK";
            }
            catch (Exception e)
            {
                Console.WriteLine("Saving file failed: {0}\n", e.Message);                
                return_value = "NOT OK";                
            } finally
            {
                if (downloadFileStream != null)
                {
                    downloadFileStream.Close();
                }
            }
            return return_value;
        }

        public static string setBlob(string filePath, string containerUri)
        {
            // sets blob content based on local file content
            if (!(File.Exists(filePath)))
            {
                throw new FileNotFoundException($"File '{filePath}' not found!");
            }

            // TODO: Check if container uri contains blob path also, like container/folder1/folder2
            // Get a credential and create a client object for the blob container.
            BlobContainerClient containerClient = new BlobContainerClient(new Uri(containerUri), new ManagedIdentityCredential());

            // Create the container if it does not exist.
            containerClient.CreateIfNotExists();

            // Get a reference to a blob
            BlobClient blobClient = containerClient.GetBlobClient(filePath);

            Console.WriteLine("Uploading to Blob storage as blob: {0}", blobClient.Uri);

            // Open the file and upload its data
            using FileStream uploadFileStream = File.OpenRead(filePath);
            try
            {
                blobClient.Upload(uploadFileStream);
                return "OK";
            } catch (Exception ex)
            {
                uploadFileStream.Close();
                throw new Exception("blah" + ex.Message, ex);
            } finally
            {
                uploadFileStream.Close();
            }
        }
    }
}
