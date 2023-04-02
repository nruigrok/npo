from typing import Sequence

import requests, csv, datetime, sys, json, argparse, os, re
from lxml import html
from dateutil.parser import parse
from amcatclient import AmcatAPI
import logging



def get_image(elem):
    images = []

    for img_cont in elem.findall('.//figure'):
        img_dict = {'type': 'figure', 'image_url': img_cont.find('.//img').attrib['src'], 'caption': '',
                    'copyright': ''}
        for span in img_cont.findall('.//figcaption/span'):
            if 'description' in span.attrib['class']: img_dict['caption'] = span.text_content()
            if 'copyright' in span.attrib['class']: img_dict['copyright'] = span.text_content()
        images.append(img_dict)

    for img_cont in elem.findall('.//div[@class = "block_video "]'):
        img_dict = {'type': 'video', 'image_url': img_cont.find('.//img').attrib['src'],
                    'video_url': 'https://nos.nl' + img_cont.find('.//a').attrib['href'],
                    'caption': ''}
        caption_content = img_cont.find('.//div[@class = "caption_content"]')
        if caption_content is not None: img_dict['caption'] = caption_content.text_content()
        images.append(img_dict)

    for img_cont in elem.xpath('.//a[contains(@class, "externalContent")]'):
        img_dict = {'type': 'link', 'url': img_cont.attrib['href'], 'image_url': '', 'title': ''}
        image = img_cont.xpath('.//div[contains(@class, "image_")]')
        if len(image) > 0:
            if 'style' in image[0].attrib:
                img_dict['image_url'] = image[0].attrib['style'].split('url(')[1].split(')')[0].strip('"')
        title = img_cont.xpath('.//div[contains(@class, "title_")]')
        if len(title) > 0: img_dict['title'] = title[0].text_content()
        images.append(img_dict)

    for img_cont in elem.xpath('.//div[contains(@class, "player_")]'):
        img_dict = {'type': 'player', 'image_url': '', 'caption': ''}
        img_str = img_cont.xpath('.//div[contains(@class, "playerOuter_")]')[0].attrib['style']
        img_dict['image_url'] = img_str.split('url(')[1].split(')')[0].strip('"')
        caption_content = img_cont.xpath('.//div[contains(@class, "caption_")]')
        if len(caption_content) > 0: img_dict['caption'] = caption_content[0].text_content()
        images.append(img_dict)
    return json.dumps(images)

def get_tweets(elem):
    tweets = []
    for tweet in elem.findall('.//a[@class = "ext-twitter"]'):
        tweet_dict = {'url': tweet.attrib['href']}
        tweet_dict['avatar'] = tweet.find('.//div[@class="ext-twitter-header__avatar"]/img').attrib['src']
        author = tweet.findall('.//div[@class="ext-twitter-header-author"]/div')
        tweet_dict['decorate_name'] = author[0].text_content()
        tweet_dict['user_name'] = author[1].text_content()
        img = tweet.find('.//div[@class = "ext-twitter-content"]/img')
        if img is not None: tweet_dict['image_url'] = img.attrib['src']
        capt = tweet.find('.//div[@class = "ext-twitter-caption"]')
        if capt is not None: tweet_dict['caption'] = capt.text_content()
        tweets.append(tweet_dict)

    for tweet in elem.xpath('.//a[contains(@class, "twitter_")]'):
        tweet_dict = {'url': tweet.attrib['href']}
        tweet_dict['avatar'] = tweet.xpath('.//div[contains(@class, "avatarImage")]')[0].attrib['src']
        author = tweet.xpath('.//div[contains(@class, "headerContent_")]/span')
        tweet_dict['decorate_name'] = author[0].text_content()
        tweet_dict['user_name'] = author[1].text_content()
        img = tweet.xpath('.//div[contains(@class, "imageWrapper_")]/img')
        if len(image) > 0: tweet_dict['image_url'] = img[0].attrib['src']
        capt = tweet.xpath('.//div[contains(@class, "text_")]')
        if len(capt) > 0: tweet_dict['caption'] = capt[0].text_content()
        tweets.append(tweet_dict)

    return json.dumps(tweets)

def get_topics(elem):
    topics = []
    for topic in elem.findall('.//a[@class="link_2imnEnEf"]'):
        topic_dict = {}
        topic_dict['topic'] = topic.text_content()
        topics.append(topic_dict)
    print(f"topics = {topics}")


url = "https://nos.nl/artikel/2410197-ook-in-alta-badia-nog-geen-olympisch-ticket-voor-skier-meiners"
url = "https://nos.nl/artikel/2410513-oostenrijk-voert-quarantaine-in-voor-niet-geboosterde-nederlanders"
page = requests.get(url)
page.raise_for_status()
tree = html.fromstring(page.text)
art = tree.find('.//article')

imgs = get_image(art)
topics = get_topics(art)
print(topics)
tweets = get_tweets(art)
print(tweets)
#article['text'], article['links_json'] = get_body(art.xpath('.//div[contains(@class, "contentBody")]')[0])
