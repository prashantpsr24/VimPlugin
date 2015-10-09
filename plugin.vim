function! Hackerrank()
python << EOF

import urllib2,urllib,time,vim
from OpenSSL import SSL
from cookielib import CookieJar
import json,string,re
import requests

#getting filename from vim WARNING language to be sent to HR is taken from extension
slugext=vim.eval("expand('%:t')")
slugext=slugext.split('.')
slug=slugext[0]
language=slugext[1]


URL = "https://www.hackerrank.com/challenges/";
try:

    # getting cookies
    session = requests.session()
    p = session.get(URL+slug)

    temp_cookies = p.cookies.get_dict();
    cookie_text = ""
    for key, value in temp_cookies.iteritems() :
            cookie_text = cookie_text + key + "=" + value + "; "

    # for csrf_token works without it too
    data = p.text.replace('\n','')
    pattern = re.compile('.*content="(.*)" name="csrf-token".*')
    csrf_token=pattern.match(data).group(1)

    headers={
            'Cookie': cookie_text,
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrf_token,
    }

    compile_url = "https://www.hackerrank.com/rest/contests/master/challenges/"+slug+"/compile_tests";

    #opening program, using vim to just take the path of file will be useful when porting for other editors
    filename = vim.eval("expand ('%:p')")
    f = open(filename, 'r')
    program=f.read()

    #sending post request to HR
    data = {'code': program, 'language': language, 'customtestcase': 'false'}
    response = requests.post(compile_url,data=json.dumps(data),headers=headers)
    j_data=json.loads(response.text)

    #looking for id and creating URL for get request
    query_id = j_data.get("model").get("id")
    # print query_id
    geturl=compile_url+'/' + str(query_id)

    # sending gets requestS
    print "WAITING FOR RESULTS"

    status=0
    cnt=0

    #Executing code takes time and if get request is sent while they are processing we need to send it again
    #just limited the requests to 5
    #status denotes they are done with executing our code or not

    while status==0 and cnt < 5:
      response1=requests.get(geturl, headers=headers)
      json_response=json.loads(response1.text)
      status = json_response.get("model").get("status")
      time.sleep(1)


    status = json_response.get("model").get("status")
    if status==0:
      print "Timed out"
      resp = json_response.get("model").get("status_string")
      print "status: "+resp

    compilemsg=json_response.get("model").get("compilemessage")
    if compilemsg != "":
      print compilemsg

    #expected and myoput are lists of lists so using expectedi and myoput is denote list inside list of list

    expected=json_response.get("model").get("expected_output")
    myoput=json_response.get("model").get("stdout")
    numtest=len(expected)
    validtest=min(len(expected),len(myoput))
    for testcases in range(numtest):
      print "########"
      print "For Sample Test File: "+str(testcases+1)+"\n\n"
      myoputi=myoput[testcases].strip()
      expectedi=expected[testcases].split('\n')
      myoputi=myoputi.split('\n')
    #counting number of cases passed in each test file.Since most of the questions have 1 sample test file
    #it makes sense to count number of inputs correctly solved in each test file
      cnt=0
      lar_len=len(expectedi)
      for i in range(lar_len):
          print "For input: "+str(i+1)
          if i >= len(myoputi):
              print "Expected: "+expectedi[i]+" Received: "+""+" --Fail"
              continue
          if expectedi[i] == myoputi[i]:
              print "Expected: "+expectedi[i]+" Received: "+myoputi[i]+" --Passed"
              cnt=cnt+1
          else:
              print "Expected: "+expectedi[i]+" Received: "+myoputi[i]+" --Fail"
      print json_response.get("model").get("testcase_message")[testcases]
      print str(cnt)+"/"+str(lar_len)+" inputs passed"

    resp=''
    status = json_response.get("model").get("status")


except Exception, e:
    print e

EOF
endfunction
