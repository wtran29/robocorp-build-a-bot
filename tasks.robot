*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             Utils/images.py
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    ${order_site}=  Get secrets from Vault
    ${order_url}=   Ask for orders url
    Open robot order site   ${order_site}[ROBOT_ORDER_SITE]
    Download Excel  ${order_url}
    ${orders}=  Get orders
    FOR  ${row}  IN  @{orders}
        Accept giving up rights
        Fill the form    ${row}
        Preview the order
        Wait Until Keyword Succeeds    5x    2s  Submit order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}   ${row}[Order number]
        Process next order
    END
    Create a receipts ZIP file
    [Teardown]    Log out and close the browser

*** Keywords ***
Open robot order site
    [Arguments]             ${order_site}
#    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser  ${order_site}


Download Excel
    [Arguments]     ${order_url}
#    https://robotsparebinindustries.com/orders.csv
    Download        ${order_url}  overwrite=True

Accept giving up rights
    Click Button    OK


Get orders
    ${table}=      Read table from CSV    orders.csv
    RETURN      ${table}

Fill the form
    [Arguments]     ${row}
    Select From List By Value   head    ${row}[Head]
    Select Radio Button         body    ${row}[Body]
    Input Text                  css:input[type="number"]    ${row}[Legs]
    Input Text                  address    ${row}[Address]

Preview the order
    Click Button    Preview
    Wait Until Element Is Visible   id:robot-preview-image


Submit order
    Click Button    id:order
    Wait Until Element Is Visible   id:receipt

Store the receipt as a PDF file
    [Arguments]     ${order_id}
    Wait Until Element Is Visible   id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${order_id}.pdf
    RETURN  ${OUTPUT_DIR}${/}receipts${/}${order_id}.pdf

Take a screenshot of the robot
    [Arguments]     ${order_id}
    Wait Until Element Is Visible   id:robot-preview-image
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}images${/}${order_id}.png
#    Resize Image    ${OUTPUT_DIR}${/}images${/}${order_id}.png
    RETURN  ${OUTPUT_DIR}${/}images${/}${order_id}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${img}  ${pdf}  ${order_id}
    Open PDF    ${pdf}
    Resize Image    ${img}  75
    Add Watermark Image To PDF  ${img}    ${pdf}  ${pdf}
#    ${files}=   Create List     ${pdf}  ${img}:align=center
#    Add Files To PDF    ${files}    ${pdf}
    Close PDF   ${pdf}

Process next order
    Click Button    id:order-another


Create a receipts ZIP file
    Archive Folder With ZIP     ${OUTPUT_DIR}${/}receipts  ${OUTPUT_DIR}${/}receipts.zip   recursive=True  include=*.pdf

Log out and close the browser
    Close browser


Ask for orders url
    Add heading     I am your assistant, Betty Bot. Would need some more info to process your orders.
    Add text input  orders_url  label=Please provide the URL of the orders CSV file.
    ${input}=       Run dialog
    RETURN          ${input.orders_url}

Get secrets from Vault
    ${secret}=      Get secret      RPA_SECRET_URL
    RETURN          ${secret}