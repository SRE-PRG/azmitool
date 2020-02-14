using System;
using System.IO;

using Azure.Core;
using Azure.Storage.Blobs;
using Azure.Identity;
using System.Collections.Generic;

namespace azmi_main
{
    public static class Operations
    {
        // Class defining main operations performed by azmi tool

        private static Exception IdentityError(string identity, Exception ex)
        {
            // if no identity, then append identity missing error, otherwise just return existing exception
            if (string.IsNullOrEmpty(identity)) {
                return new ArgumentNullException("Missing identity argument", ex);
            } else if (ex.Message.Contains("See inner exception for details.") 
                && (ex.InnerException != null) 
                && (ex.InnerException.Message.Contains("Identity not found"))) {
                return new ArgumentException("Managed identity not found", ex);
            } else {
                return ex;
            }
        }

        public static string getToken(string endpoint = "management", string identity = null)
        {
            var Cred = new ManagedIdentityCredential(identity);
            if (string.IsNullOrEmpty(endpoint)) { endpoint = "management"; };
            var Scope = new String[] { $"https://{endpoint}.azure.com" };
            var Request = new TokenRequestContext(Scope);

            try
            {
                var Token = Cred.GetToken(Request);
                return Token.Token;
            } catch (Exception ex)
            {
                throw IdentityError(identity, ex);
            }
        }

        public static string getBlob(string blobURL, string filePath, string identity = null)
        {
            // Download the blob to a local file
            var Cred = new ManagedIdentityCredential(identity);
            var blobClient = new BlobClient(new Uri(blobURL), Cred);
            try
            {
                blobClient.DownloadTo(filePath);
                return "Success";
            } catch (Exception ex)
            {
                throw IdentityError(identity, ex);
            }
        }

        public static string listBlobs(string containerUri, string identity = null, string prefix = null)
        {
            var Cred = new ManagedIdentityCredential(identity);
            var containerClient = new BlobContainerClient(new Uri(containerUri), Cred);
            containerClient.CreateIfNotExists();
            var blobNamesList = new List<string>();

            try
            {
                foreach (var blob in containerClient.GetBlobs(prefix: prefix))
                {
                    blobNamesList.Add(blob.Name);
                }

                return blobNamesList.Count == 0 ? null : String.Join("\n", blobNamesList);
            }
            catch (Exception ex)
            {
                throw IdentityError(identity, ex);
           }
        }

        public static string setBlob_byContainer(string filePath, string containerUri, bool force = false, string identity = null)
        {
            // sets blob content based on local file content in provided container
            if (!(File.Exists(filePath))) {
                throw new FileNotFoundException($"File '{filePath}' not found!");
            }

            var Cred = new ManagedIdentityCredential(identity);
            var containerClient = new BlobContainerClient(new Uri(containerUri), Cred);
            containerClient.CreateIfNotExists();
            var blobClient = containerClient.GetBlobClient(filePath.TrimStart('/'));
            try
            {
                blobClient.Upload(filePath, force);
                return "Success";
            } catch (Exception ex)
            {
                throw IdentityError(identity, ex);
            }
        }       

        public static string setBlob_byBlob(string filePath, string blobUri, bool force = false, string identity = null)
        {
            // sets blob content based on local file content with provided blob url
            if (!(File.Exists(filePath)))
            {
                throw new FileNotFoundException($"File '{filePath}' not found!");
            }

            var Cred = new ManagedIdentityCredential(identity);
            var blobClient = new BlobClient(new Uri(blobUri), Cred);
            try
            {
                blobClient.Upload(filePath, force);
                return "Success";
            } catch (Exception ex)
            {
                throw IdentityError(identity, ex);
            }
        }
    }
}
