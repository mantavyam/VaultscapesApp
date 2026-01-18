### Blocks

GitBook is a block-based editor. That means you can add different kinds of blocks to your page — from standard text and images to more advanced, interactive blocks. Your pages can include any combination of blocks you want, and there’s no limit to the number of blocks you can have on a page.

Block-based editing makes it easy to reorganize your content using drag-and-drop, or add new blocks in the middle of existing content. You can create new blocks using the editor interface, or create and format blocks using Markdown.

Discover all the blocks you can use in GitBook [in the Blocks section](https://gitbook.com/docs/creating-content/blocks).

[Blocks](https://gitbook.com/docs/creating-content/blocks)

- [Paragraphs](https://gitbook.com/docs/creating-content/blocks/paragraph) 
```
Because a paragraph block is just text, that’s how it’s represented in Markdown.
```
- [Headings](https://gitbook.com/docs/creating-content/blocks/heading)
```
# I'm a page title
## My heading 1
### My heading 2
#### My heading 3
```
- [Unordered lists](https://gitbook.com/docs/creating-content/blocks/unordered-list)
```
- Item
   - Nested item
      - Another nested item
   - Yet another nested item
- Another item
- Yet another item
```
- [Ordered lists](https://gitbook.com/docs/creating-content/blocks/ordered-list)
```
1. Item 1
   2. Nested item 1.1
      1. Nested item 1.1.1
   3. Nested item 1.2
4. Item 2
5. Item 3
```
- [Task lists](https://gitbook.com/docs/creating-content/blocks/task-list)
```
- [ ] Here’s a task that hasn’t been done
  - [x] Here’s a subtask that has been done, indented using `tab`
  - [ ] Here’s a subtask that hasn’t been done.
- [ ] Finally, an item, unidented using `shift` + `tab`.
```
- [Hints](https://gitbook.com/docs/creating-content/blocks/hint)
```
{% hint style="info" %}
**Info hints** are great for showing general information, or providing tips and tricks.
{% endhint %}

{% hint style="success" %}
**Success hints** are good for showing positive actions or achievements.
{% endhint %}

{% hint style="warning" %}
**Warning hints** are good for showing important information or non-critical warnings.
{% endhint %}

{% hint style="danger" %}
**Danger hints** are good for highlighting destructive actions or raising attention to critical information.
{% endhint %}

{% hint style="info" %}

## This is a H2 heading

This is a line

This is an inline <img src="../../.gitbook/assets/25_01_10_command_icon_light.svg" alt="The Apple computer command icon" data-size="line"> image

- This is a second <mark style="color:orange;background-color:purple;">line using an unordered list and color</mark>
{% endhint %}
```
- [Quotes](https://gitbook.com/docs/creating-content/blocks/quote)
```
> "No human ever steps in the same river twice, for it’s not the same river and they are not the same human." — _Heraclitus_
```

- [Code blocks](https://gitbook.com/docs/creating-content/blocks/code-block)

```
{% code title="index.js" overflow="wrap" lineNumbers="true" %}
```javascript
‌import * as React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

ReactDOM.render(<App />, window.document.getElementById('root'));
```
{% endcode %}

- [Files](https://gitbook.com/docs/creating-content/blocks/insert-files)
```
{% file src="https://example.com/example.pdf" %}
    This is a caption for the example file.
{% endfile %}
```
- [Images](https://gitbook.com/docs/creating-content/blocks/insert-images)
```
//Simple Block
![](https://gitbook.com/images/gitbook.png)

//Block with Caption
![The GitBook Logo](https://gitbook.com/images/gitbook.png)

//Block with Alt text

<figure><img src="https://gitbook.com/images/gitbook.png" alt="The GitBook Logo"></figure>

//Block with Caption and Alt text

<figure><img src="https://gitbook.com/images/gitbook.png" alt="The GitBook Logo"><figcaption><p>GitBook Logo</p></figcaption></figure>

// Block with framed image

<div data-with-frame="true"><img src="https://gitbook.com/images/gitbook.png" alt="The GitBook Logo"></div>

//Block with different image for dark and light mode, with caption

<figure>
  <picture>
    <source srcset="https://user-images.githubusercontent.com/3369400/139447912-e0f43f33-6d9f-45f8-be46-2df5bbc91289.png" media="(prefers-color-scheme: dark)">
    <img src="https://user-images.githubusercontent.com/3369400/139448065-39a229ba-4b06-434b-bc67-616e2ed80c8f.png" alt="GitHub logo">
  </picture>
  <figcaption>Caption text</figcaption>
</figure>
```
- [Embedded URLs](https://gitbook.com/docs/creating-content/blocks/embed-a-url)
```
{% embed url="URL_HERE" %}
```
- [Tables](https://gitbook.com/docs/creating-content/blocks/table)
```
# Table

|   |   |   |
| - | - | - |
|   |   |   |
|   |   |   |
|   |   |   |
```
- [Cards](https://gitbook.com/docs/creating-content/blocks/cards)
```
<table data-view="cards">
  <thead>
    <tr>
      <th></th>
      <th></th>
      <th data-hidden data-card-target data-type="content-ref"></th>
      <th data-hidden data-card-cover data-type="files"></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Example title 1</strong></td>
      <td>Example description 1.</td>
      <td><a href="https://example.com">https://example.com</a></td>
      <td><a href="https://example.com/image1.svg">example_image1.svg</a></td>
    </tr>
    <tr>
      <td><strong>Example title 2</strong></td>
      <td>Example description 2.</td>
      <td><a href="https://example.com">https://example.com</a></td>
      <td><a href="https://example.com/image2.svg">example_image2.svg</a></td>
    </tr>
    <tr>
      <td><strong>Example title 3</strong></td>
      <td>Example description 3.</td>
      <td><a href="https://example.com">https://example.com</a></td>
      <td><a href="https://example.com/image3.svg">example_image3.svg</a></td>
    </tr>
  </tbody>
</table>
```
- [Tabs](https://gitbook.com/docs/creating-content/blocks/tabs)
```
{% tabs %}

{% tab title="Windows" %} Here are the instructions for Windows {% endtab %}

{% tab title="OSX" %} Here are the instructions for macOS {% endtab %}

{% tab title="Linux" %} Here are the instructions for Linux {% endtab %}

{% endtabs %}
```
- [Expandable](https://gitbook.com/docs/creating-content/blocks/expandable)
```
# Expandable blocks

<details>

<summary>Add content to Expandable block</summary>

Once you’ve inserted an expandable block, you can add content to it — including lists and code blocks.

</details>
```
- [Stepper](https://gitbook.com/docs/creating-content/blocks/stepper)
```
## Example

{% stepper %}
{% step %}
### Step 1 title
Step 1 text
{% endstep %}
{% step %}
### Step 2 title
Step 2 text
{% endstep %}
{% endstepper %}
```
- [Updates](https://gitbook.com/docs/creating-content/blocks/updates)
```
{% update date="2025-12-25 %}
## A brand new update

This block is perfect for telling users all about a brand new update to your product. You can easily add other blocks within this update block, including images, code, lists and much more.
{% endupdate %}
```
- [Drawings](https://gitbook.com/docs/creating-content/blocks/drawing)
```
<img src="https://example.com/file.svg" alt="Example diagram description" class="gitbook-drawing">
```
- [Math & TeX](https://gitbook.com/docs/creating-content/blocks/math-and-tex)
```
# Math and TeX block

$$f(x) = x * e^{2 pi i \xi x}$$
```
- [Page links](https://gitbook.com/docs/creating-content/blocks/page-link)
```
{% content-ref url="./" %} . {% endcontent-ref %}
```
- [Columns](https://gitbook.com/docs/creating-content/blocks/columns)
```
## Example





### Create a seamless experience between your docs and product

Integrate your documentation right into your product experience, or give users a personalized experience that gives them what they need faster.

<a href="https://www.gitbook.com/#alpha-waitlist" class="button primary">Learn more</a>





<figure><img src="../../.gitbook/assets/GitBook vision post.png" alt="An image of GitBook icons demonstrating side by side column functionality"><figcaption></figcaption></figure>




```
- [Conditional content](https://gitbook.com/docs/creating-content/blocks/conditional-content)
```
## Example

{% if visitor.claims.unsigned.example_attribute_A %}
This block is only visible to users **with** attribute A.
<a href="https://gitbook.com/docs/creating-content/blocks/conditional-content?visitor.example_attribute_A=false" class="button primary">View without attribute A</a>
{% endif %}

{% if !visitor.claims.unsigned.example_attribute_A %}
This block is only visible to users **without** attribute A.
<a href="https://gitbook.com/docs/creating-content/blocks/conditional-content?visitor.example_attribute_A=true" class="button primary">View with attribute A</a>
{% endif %}
```
- [Buttons](https://gitbook.com/docs/creating-content/formatting/inline#buttons)
```
<a href="https://app.gitbook.com" class="button primary">GitBook</a>
```
- [Icons](https://gitbook.com/docs/creating-content/formatting/inline#icons)
```
<i class="fa-github">:github:</i>
```
- [Expressions](https://gitbook.com/docs/creating-content/formatting/inline#expressions)
```
```
### Markdown editing

GitBook’s editor allows you to create and format content blocks using Markdown.

Markdown is a popular markup syntax that’s widely known for its simplicity. GitBook supports it as a keyboard-friendly way to write rich and structured text — all of GitBook’s blocks can be written using Markdown syntax.

| Type                                                                                  | Or                                                                                | … to Get                                                              |
| ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| *Italic*                                                                              | _Italic_                                                                          | _Italic_                                                              |
| **Bold**                                                                              | __Bold__                                                                          | **Bold**                                                              |
| # Heading 1                                                                           | Heading 1  <br>=========                                                          | # Heading 1                                                           |
| ## Heading 2                                                                          | Heading 2  <br>---------                                                          | ## Heading 2                                                          |
| [Link](http://a.com)                                                                  | [Link][1]  <br>⋮  <br>[1]: http://b.org                                           | [Link](https://commonmark.org/)                                       |
| ![Image](http://url/a.png)                                                            | ![Image][1]  <br>⋮  <br>[1]: http://url/b.jpg                                     | ![Markdown](https://commonmark.org/help/images/favicon.png)           |
| > Blockquote                                                                          |                                                                                   | > Blockquote                                                          |
| * List  <br>* List  <br>* List                                                        | - List  <br>- List  <br>- List                                                    | - List<br>- List<br>- List                                            |
| 1. One  <br>2. Two  <br>3. Three                                                      | 1) One  <br>2) Two  <br>3) Three                                                  | 1. One<br>2. Two<br>3. Three                                          |
| Horizontal rule:  <br>  <br>---                                                       | Horizontal rule:  <br>  <br>***                                                   | Horizontal rule:<br><br>---                                           |
| `Inline code` with backticks                                                          |                                                                                   | `Inline code` with backticks                                          |
| ```<br># code block  <br>print '3 backticks or'  <br>print 'indent 4 spaces'  <br>``` | ····# code block  <br>····print '3 backticks or'  <br>····print 'indent 4 spaces' | # code block  <br>print '3 backticks or'  <br>print 'indent 4 spaces' |
