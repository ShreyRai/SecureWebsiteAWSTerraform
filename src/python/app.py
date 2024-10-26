from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "<h1>Welcome to My Flask App on EC2</h1><p>This is dynamic content served by Flask!</p>"

@app.route('/goku')
def goku():
    return "<h1>KAMEHAMEHAAAAA!!!!!!!!!!!</h1><p>kABooooomMM!</p>"

@app.route('/vegeta')
def vegeta():
    return "<h1>FINAL FLAAAAASSHHHH!!</h1><p>ded!</p>"

@app.route('/gojo')
def gojo():
    return "<h1>DOMAIN EXPANSION!!!!</h1><p>Infinity</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
