# BREAKTHROUGH:
## Current Limitation:
- When closing the archive Bottom Sheet the app goes blank and does not respond and user has to completely exit the app and restart it from beginning.
- Bottomsheet unable to close automatically when user clicks on the respected links, it gets opened within bottomsheet only not as per our strategy.
- the text 'archive' displayed in the bottomsheet shall be changed to 'Select Article from Archive'
- there must be some minimal padding in the bottom sheet to contain the webview from the sideways.
- user shall also be able to interact with the webview of archive in the bottom sheet by scrolling vertically.

## Changes
- As earlier instructed that In the Breakthrough UI Screen the functionality was limited to a single webpage content display only but I have a plethora of content in the archive section of the website, so I would like to enable the feature of displaying them as well.
- How to Implement Archive Navigation?
	- Archive Button at Bottom which opens up a BottomSheet upto the middle of screen height as per device and that sheet shall display the content of 'https://alphasignal.ai/archive' 
	- When user selects a particular page on this bottom sheet then it's link shall open in the Webview of 'Breakthrough' and the Bottom Sheet shall close automatically.
    - We'll need a functionality to detect gestures on the bottom sheet and any request immediately being sent must display a LinearProgress Indicator of shadcn_flutter on the bottomsheet and it shall close the drawer to hide it from the view and the requested content shall be served in the full screen of the Breakthrough UI Screen.
- I want to hide the following from the webview and always make sure the webview gets loaded only after these are hidden until then display a 'LinearProgressIndicator' from shadcn_flutter along with a text randomly being displayed out of the following versions = 'Updated daily except weekends' , 'Our algos spent the night splitting signal from noise', 'Your AI Briefing will be ready soon', 'Stay Ahead of the Curve with Vaultscapes', 'You can finally take a break from AI firehose', 'Fetching Top News, Models, Papers and Repos'.
- You must read the file '.claude/breakthrough-strategy.md' to understand the Hiding Strategy for the elements described below:

## If Webview = 'https://alphasignal.ai/last-email' or of type 'https://alphasignal.ai/email/id' example 'https://alphasignal.ai/email/5ec45b516be509ff' then hide the following 5 things:

### Social Links
```
<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="max-width:600px;margin:0 auto;" width="100%">
<tbody><tr>
<td align="center" style="padding:6px 0 2px 0;text-align:center;">
<table align="center" border="0" cellpadding="0" cellspacing="0" class="menu-bar" role="presentation" style="display:inline-table;margin:0 auto;text-align:center;">
<tbody><tr>
<td style="font-size:12px;line-height:18px;font-family:Helvetica, Arial, sans-serif;">
<a href="https://alphasignal.ai/?utm_source=email" style="text-decoration:none;color:#000000 !important;
                      font-family:Helvetica, Arial, sans-serif;
                      font-size:12px;line-height:18px;" target="_blank">
              Signup
            </a>
</td>
<td style="font-size:13px;line-height:18px;color:#000000;
                     font-family:Helvetica, Arial, sans-serif;">|</td>
<td style="font-size:12px;line-height:18px;font-family:Helvetica, Arial, sans-serif;">
<a href="https://wsndcchuur6.typeform.com/to/t0Ry7qsf" style="text-decoration:none;color:#000000 !important;
                      font-family:Helvetica, Arial, sans-serif;
                      font-size:12px;line-height:18px;" target="_blank">
              Work With Us
            </a>
</td>
<td style="font-size:13px;line-height:18px;color:#000000;
                     font-family:Helvetica, Arial, sans-serif;">|</td>
<td style="font-size:12px;line-height:18px;font-family:Helvetica, Arial, sans-serif;">
<a href="https://x.com/AlphaSignalAI" style="text-decoration:none;color:#000000 !important;
                      font-family:Helvetica, Arial, sans-serif;
                      font-size:12px;line-height:18px;" target="_blank">
              Follow on X
            </a>
</td>
</tr>
</tbody></table>
</td>
</tr>
</tbody></table>
```

### Author Section
```
<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="max-width:600px;margin:auto;border:1px solid #000000;
              background-color:#ffffff;padding:15px 20px 20px 20px;margin-bottom:30px;" width="100%">
<tbody><tr>
<!-- Profile Image -->
<td style="padding-right:12px;" valign="top" width="70">
<img alt="Author photo" height="60" src="https://pbs.twimg.com/profile_images/1980366446975766528/LPbXxZYl_400x400.jpg" style="display:block;border:1px solid #000000;outline:none;text-decoration:none;" width="60">
</td>
<!-- Text Content -->
<td style="font-family:system-ui, Helvetica, Arial, sans-serif;color:#000000;" valign="middle">
<div style="font-size:15px;font-weight:700;line-height:20px;margin:0 0 3px 0;padding:0;">
        Today's Author
      </div>
<div style="font-size:15px;line-height:20px;margin:0;padding:0;">
        Lior Alexander. Founder of AlphaSignal and former ML Engineer.
Previously built ML systems at Iguazio, Guesty, Enphase, Mila.
      </div>
</td>
</tr>
</tbody></table>
```

### Promotion Section
```
<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="max-width:600px;width:100%;margin:auto;border:1px solid #000000;
         background-color:#ffffff;margin-bottom:30px;" width="100%">
<tbody><tr>
<!-- Outer wrapper with 20px padding -->
<td style="padding:20px;">
<table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
<!-- Text Content -->
<tbody><tr>
<td align="center" class="p" style="font-family:Helvetica, Arial, sans-serif;
           font-size:15px !important;
           line-height:22.5px;
           font-weight:normal;
           color:#000000 !important;
           mso-color-alt:#000000;
           mso-style-textfill-fill-color:#000000;
           padding:0;">
  Looking to promote your company, product, service, or event to 250,000+ AI developers?
</td>
</tr>
<tr>
<td align="center" style="padding:10px 0 0 0;">
<table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin:auto;">
<tbody><tr>
<td align="center" bgcolor="#f74904" style="font-family:Helvetica, Arial, sans-serif;font-size:16px;line-height:20px;
                           font-weight:bold;padding:12px 12px;color:#ffffff !important;
                           border:1px solid #000000;display:block;">
<a href="https://wsndcchuur6.typeform.com/to/t0Ry7qsf" style="color:#ffffff !important;text-decoration:none;display:inline-block;" target="_blank">
                    WORK WITH US
                  </a>
</td>
</tr>
</tbody></table>
</td>
</tr>
</tbody></table>
</td>
</tr>
</tbody></table>
```

### Ratings Section
```
<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="max-width:600px;margin:auto;border:1px solid #000;background-color:#ffffff;" width="100%">
<tbody><tr>
<td align="center" style="padding:30px 20px;background-color:#ffffff;">
<!-- Title -->
<div style="font-family:Helvetica, Arial, sans-serif;
               font-size:18px;line-height:24px;font-weight:bold;
               color:#000000;
               padding:0 0 20px 0;">
        How was today’s email?
      </div>
<!-- Buttons -->
<div style="font-family:Helvetica, Arial, sans-serif;font-size:16px;line-height:22px;">
<a href="{{ FEEDBACK_AWESOME }}" style="display:inline-block;
                  text-decoration:none;
                  color:#000000;
                  border:1px solid #000000;
                  padding:10px 16px;
                  margin:0 6px;" target="_blank">
          Awesome
        </a>
<a href="{{ FEEDBACK_DECENT }}" style="display:inline-block;
                  text-decoration:none;
                  color:#000000;
                  border:1px solid #000000;
                  padding:10px 16px;
                  margin:0 6px;" target="_blank">
          Decent
        </a>
<a href="{{ FEEDBACK_NOT_GREAT }}" style="display:inline-block;
                  text-decoration:none;
                  color:#000000;
                  border:1px solid #000000;
                  padding:10px 16px;
                  margin:0 6px;" target="_blank">
          Not Great
        </a>
</div>
</td>
</tr>
</tbody></table>
```

### Footer
```
<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="max-width:600px;margin:auto;" width="100%">
<tbody><tr>
<td align="center" style="padding:20px 10px;">
<!-- Unsubscribe -->
<a href="https://alphasignal.ai/unsubscribe" style="font-family:system-ui;
                font-size:14px;line-height:20px;
                text-decoration:none;color:#f74904 !important;
                mso-color-alt:#f74904;
                mso-style-textfill-fill-color:#f74904;" target="_blank">
       unsubscribe_me(): return True
      </a>
<!-- Address -->
<div style="padding-top:20px; font-family:system-ui;font-size:14px;color:#a1a1a1;">
{"AlphaSignal": "214 Barton Springs Rd, Austin, USA"}
</div>
</td>
</tr>
</tbody></table>
```

## If Bottomsheet displaying webview = 'https://alphasignal.ai/archive' then hide the header and footer classes before loading the content and display a LinearProgressIndicator until content is hidden and ready to view:

### Header
```
<header class="undefined bg-[rgba(217,217,217,0)] backdrop-blur-sm flex justify-between items-center p-4 border-b border-custom-blue-100 md:px-20 relative" style="z-index: 1000;"><div class="flex items-center"><a class="md:hidden" href="/"><svg width="32" height="26" viewBox="0 0 20 16" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10.9953 fill="#E8EAED"></path></svg></a></div><div class="flex items-center"><a href="https://wsndcchuur6.typeform.com/to/t0Ry7qsf" target="_blank"><button class="focus:outline-none transition-all duration-200 px-6 py-2 text-sm border border-custom-blue-200 text-white md:ml-3 hidden md:block" type="button">Advertise</button></a></div></header>
```

### Footer
```
<footer class="block md:hidden text-gray-500 text-xs md:pb-5 text-center border-t border-custom-blue-300 md:border-none pt-4 md:pt-0"><div class="">©2025 AlphaSignal, All Rights Reserved.</div><div class="mt-2"><a href="https://alphasignal.ai/policy" target="_blank">Privacy Policy</a> \ <a href="https://alphasignal.ai/tos-policy" target="_blank">Terms of Service</a></div></footer>

```
# Guidelines
- To better understand the Application there is a reference directory provided exclusively for this purpose given under the .claude/reference, you may read it for improved contextual understanding.
- After Making sure these fixes are addressed. then always:
✅ flutter analyze - Only warnings (no errors)
✅ flutter build apk --debug - Built successfully
✅ flutter run - App running on SM S918B (wireless)
✅ No runtime errors in debug console
# Constraints
- Do not presume with Material, Always use the context7 MCP Server and query the shadcn_flutter package documentation to understand the implementation of the components before implementing that, note that there are some key differences in shadcn_flutter as compared to the regular Material or Cupertino Implementation. For Components exclusively not offered by shadcn_flutter (Dual Confirm from context7 query and the appendix given in the #file:ui-ux.md) use the regular Material ones but always make it's looks resemble the styling of shadcn with responsiveness too. 
- Make sure all your changes do not affect the actual core functionality of the main content and it's data management and presentation, most changes requested above are more of UI based and shall not break already existing core features.