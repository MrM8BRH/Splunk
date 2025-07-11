[Getting Microsoft Azure data into the Splunk platform](https://docs.splunk.com/Documentation/SVA/current/Architectures/AzureGDI)

![800px-Azure_-_GDI_Splunk_Cloud](https://github.com/user-attachments/assets/66561dae-9628-4370-8907-a4f27acee783)


MS Office 365

[Configure an integration application in Microsoft Entra ID (Azure AD) for the Splunk Add-on for Microsoft Office 365](https://splunk.github.io/splunk-add-on-for-microsoft-office-365/ConfigureAppinAzureAD/)

[Configure a Tenant in the Splunk Add-on for Microsoft Office 365](https://splunk.github.io/splunk-add-on-for-microsoft-office-365/ConfigureTenant/)

[Grant tenant-wide admin consent to an application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent?pivots=portal)

[Register a Microsoft Entra app and create a service principal](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)

```
Step 1
- Go to admin.microsoft.com.
- On the left blade click on show all
- Navigate to Security, then click on search, under search click on Audit log search, Turn on auditing 

Step 2
- Kindly go to Azure portal, navigate to app registration, go to API permission, click add permission.
- Scroll down and look for Office 365 Management APIs, click on application permission, select all of the permissions and grant the admin consent.
```

Windows Console

[How to Determine What Just Ran on Windows Console](https://devblogs.microsoft.com/commandline/how-to-determine-what-just-ran-on-windows-console/)
