import time
from selenium import webdriver
import requests
import json
from multiprocessing.dummy import Pool
import random

'''
ideas:
create new account everytime you checkout
use that proxy finder that was made for csec380 and use those proxies 
'''
#options = webdriver.ChromeOptions()
#options.add_argument('user-data-dir=C:\Users\nickm\AppData\Local\Google\Chrome\User Data\Profile') #Path to your chrome profile
#w =webdriver.Chrome(executable_path="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe", chrome_options=options)
'''
#threading:
def test(i):
    driver = webdriver.Chrome('C:\\Users\\nickm\\Downloads\\chromedriver_win32\\chromedriver')
    driver.get('https://target.com')
    print("here1")
    driver.get('https://target.com')
    driver.get("https://login.target.com/gsp/static/v1/login/?client_id=ecom-web-1.0.0&ui_namespace=ui-default&back_button_action=browser&keep_me_signed_in=true&kmsi_default=false&actions=create_session_signin")
    print("here")
    time.sleep(5) # Let the user actually see something!
    time.sleep(5) # Let the user actually see something!
    print(i, " finished")
    driver.quit()
p = Pool(5)                   #The start of the threading magic
p.map(test,range(5))  #Without threading, it takes way too long to run
p.close()
p.join()
'''
def get_keys(product_url):
    response = requests.get(product_url)
    apikey = str(response.text).split("apiKey")[1].split('"')[2]
    tcin=str(response.text).split("sku")[1].split('"')[2]
    return apikey,tcin
def checkifinstock(product_urls):
    i=0
    instock=False
    while instock is False:
        for url in product_urls:
            time.sleep(1)
            apikey, product_tcin = get_keys(url)
            #print(apikey)
            #print(product_tcin)
            parmas = {'key': apikey, 'tcin': product_tcin, 'store_id': '1157','store_positions_store_id':'1157','has_store_positions_store_id':'true', 'zip':'14450','state':'NY','latitude':'43.091156005859375','longitude':'-77.42955017089844','scheduled_delivery_store_id':'1195','pricing_store_id':'1157','fulfillment_test_mode':'grocery_opu_team_member_test','is_bot':'false'}
            response = requests.get("https://redsky.target.com/redsky_aggregations/v1/web/pdp_fulfillment_v1?",params=parmas)
            #print("checking if it is instock")
            #print("response: ", response)
            #print("response.headers: ", response.headers)
            print("response.text: ",i, response.text)
            if( '"shipping_options":{"availability_status":"OUT_OF_STOCK"' not in str(response.text) ):
                instock =True
                method="shipping"
                print("it is instock for shipping")
            if( '"order_pickup":{"availability_status":"UNAVAILABLE"' not in str(response.text) ):
                instock =True
                method="pickup"
                print("it is instock for order pickup")
            if( '"ship_to_store":{"availability_status":"UNAVAILABLE"}' not in str(response.text) ):
                instock =True
                method="shiptostore"
                print("it is instock for shipping to store")
            if instock is True:
                return url
           

def addtocart_pickup(req,product_url,apikey,tcin):
    headers = {'Host': 'carts.target.com',
               'Connection': 'keep-alive',
               'Content-Length': '209',
               'Accept': 'application/json',
               'x-application-name': 'web',
               'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
               'Content-Type': 'application/json',
               'Origin': 'https://www.target.com',
               'Sec-Fetch-Site': 'same-site',
               'Sec-Fetch-Mode': 'cors',
               'Sec-Fetch-Dest': 'empty',
               'Referer': product_url,
               'Accept-Encoding': 'gzip, deflate, br',
               'Accept-Language': 'en-US,en;q=0.9'
               }
    parmas = {'field_groups': 'CART%2CCART_ITEMS%2CSUMMARY', 'key': apikey}
    data = {"cart_type": "REGULAR", "channel_id": "90", "shopping_context": "DIGITAL",
            "cart_item": {"tcin": tcin, "quantity": 1, "item_channel_id": "10"},
            "fulfillment": {"fulfillment_test_mode": "grocery_opu_team_member_test","location_id": "1157","ship_method": "STORE_PICKUP"}}

    response = req.post('https://carts.target.com/web_checkouts/v1/cart_items?', data=json.dumps(data), headers=headers,params=parmas)
    print("____adding to Cart_______")
    print("response: ", response)
    print("response.headers: ", response.headers)
    print("response.text: ", response.text)
    print("response.reason: ", response.reason)
    print("response.json():",response.json())
    print("____ended adding to Cart_______")


def request(driver):
    s = requests.Session()
    cookies = driver.get_cookies()
    for cookie in cookies:
        s.cookies.set(cookie['name'], cookie['value'])
    return s


def login():
    options = webdriver.ChromeOptions()
    options.add_argument("user-data-dir=/tmp/.org.chromium.Chromium.tilcID/Profile 1")
    #options.add_argument('--headless')
    #options.add_argument('--disable-gpu')
    driver = webdriver.Chrome('/usr/lib/chromium-browser/chromedriver', options=options)
    #driver = webdriver.Chrome('/usr/lib/chromium-browser/chromedriver')
    driver.get('https://target.com')
    #driver.find_element_by_id('account').click()
    #driver.find_element_by_id('accountNav-signIn').click()
    #driver.find_element_by_id('username').send_keys("nickman3422@gmail.com ")
    #driver.find_element_by_id('password').send_keys("ThisisAPassword1234")
    #driver.find_element_by_id('login').click()
    #time.sleep(1000)
    # Now move to other pages using requests
    #add while and if statement with a get to desired product to check if it is in stock and if it is then send post request to add it to cart and checkout 
    req = request(driver)
    return req

def checkout(req,product_url,apikey,tcin):
    parmas = {'cart_type':'SFL','field_groups': 'CART%2CCART_ITEMS%2CSUMMARY', 'key': apikey}
    response = req.get("https://carts.target.com/web_checkouts/v1/cart_views?", parmas=parmas)
    cartid=str(response.text).split("cart_id")[1].split('"')[2]
    headers = {'Origin': 'https://www.target.com',
               'Connection': 'keep-alive',
               'Content-Length': '23',
               'Accept': 'application/json',
               'x-application-name': 'web',
               'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
               'Content-Type': 'application/json',
               'Sec-Fetch-Site': 'same-site',
               'Sec-Fetch-Mode': 'cors',
               'Sec-Fetch-Dest': 'empty',
               'Referer': 'https://www.target.com/co-review?precheckout=true',
               'Accept-Encoding': 'gzip, deflate, br',
               'Accept-Language': 'en-US,en;q=0.9'
               }
    parmas = {'field_groups': 'ADDRESSES%2CCART%2CCART_ITEMS%2CDELIVERY_WINDOWS%2CPAYMENT_INSTRUCTIONS%2CPICKUP_INSTRUCTIONS%2CPROMOTION_CODES%2CSUMMARY&', 'key': apikey}
    data = {"cart_type": "REGULAR"}
    response = req.post("https://carts.target.com/web_checkouts/v1/pre_checkout?",data=json.dumps(data),headers=headers,parmas=parmas)
    print("____first of checkout_______")
    print("response: ", response)
    print("response.headers: ", response.headers)
    print("response.text: ", response.text)
    print("response.reason: ", response.reason)
    print("response.json():",response.json())
    print("____ended first of checkout_______")

    #checkout:
    #enter card number:
    headers = {'Origin': 'https://www.target.com',
               'Connection': 'keep-alive',
               'Content-Length': '39',
               'Accept': 'application/json',
               'x-application-name': 'web',
               'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
               'Content-Type': 'application/json',
               'Sec-Fetch-Site': 'same-site',
               'Sec-Fetch-Mode': 'cors',
               'Sec-Fetch-Dest': 'empty',
               'Referer': 'https://www.target.com/co-review',
               'Accept-Encoding': 'gzip, deflate, br',
               'Accept-Language': 'en-US,en;q=0.9'
               }
    parmas = {'key': apikey}
    data = {"cart_id":cartid,"card_number":"4767718349196032"}
    response = req.post("https://carts.target.com/checkout_payments/v1/credit_card_compare?",data=json.dumps(data),headers=headers, parmas=parmas)
    print("____card information_______")
    print("response: ", response)
    print("response.headers: ", response.headers)
    print("response.text: ", response.text)
    print("response.reason: ", response.reason)
    print("response.json():",response.json())
    print("____ended card information_______")

    #place order:
    headers = {'Origin': 'https://www.target.com',
           'Connection': 'keep-alive',
           'Content-Length': '39',
           'Accept': 'application/json',
           'x-application-name': 'web',
           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36',
           'Content-Type': 'application/json',
           'Sec-Fetch-Site': 'same-site',
           'Sec-Fetch-Mode': 'cors',
           'Sec-Fetch-Dest': 'empty',
           'Referer': 'https://www.target.com/co-review',
           'Accept-Encoding': 'gzip, deflate, br',
           'Accept-Language': 'en-US,en;q=0.9'
           }
    parmas = {'field_groups':'ADDRESSES%2CCART%2CCART_ITEMS%2CDELIVERY_WINDOWS%2CPAYMENT_INSTRUCTIONS%2CPICKUP_INSTRUCTIONS%2CPROMOTION_CODES%2CSUMMARY&','key':apikey}
    data = {"cart_type": "REGULAR","channel_id":10}
    response = req.post("https://carts.target.com/web_checkouts/v1/checkout?",data=json.dumps(data),headers=headers,parmas=parmas)
    print("____placing order_______")
    print("response: ", response)
    print("response.headers: ", response.headers)
    print("response.text: ", response.text)
    print("response.reason: ", response.reason)
    print("response.json():",response.json())
    print("____ended placing order_______")

#product_urls=["https://www.target.com/p/2020-nfl-mosaic-football-trading-card-blaster-box/-/A-80846428","https://www.target.com/p/2020-nfl-donruss-football-trading-card-blaster-box/-/A-80140513","https://www.target.com/p/2020-topps-mlb-bowman-baseball-trading-card-mega-box/-/A-79366642"]
product_urls=["https://www.target.com/p/playstation-5-console/-/A-81114595#lnk=sametab"]
url=checkifinstock(product_urls)
apikey,product_tcin=get_keys(url)
print(apikey)
print(product_tcin) 
req=login()
addtocart(req,url,apikey,product_tcin)
checkout(req,product_url,apikey,product_tcin)
time.sleep(100)
