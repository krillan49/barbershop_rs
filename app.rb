require 'sinatra'
require 'sqlite3'
require 'pony'

# методы для помещения парикмахеров в таблицу Barbers если их там еще нет.
def is_barber_exists?(db, name)
  db.execute('SELECT * FROM Barbers WHERE name=?', [name]).size > 0
end
def seed_db(db, barbers)
  barbers.each do |barber|
    if !is_barber_exists?(db, barber)
      db.execute 'INSERT INTO Barbers (name) VALUES (?)', [barber]
    end
  end
end

# метод открывающий/создающий базу данных и устанавливающий вывод строк запросов в виде хэша
def get_db
	db = SQLite3::Database.new './db/barbershop.db'
	db.results_as_hash = true
	db
end

before do
  db = get_db
	@barbers = db.execute('SELECT * FROM Barbers')
	db.close
end

configure do
	db = get_db()
	db.execute 'CREATE TABLE IF NOT EXISTS "Users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "username" TEXT, "phone" TEXT, "datestamp" TEXT, "barber" TEXT, "color" TEXT)'
  db.execute 'CREATE TABLE IF NOT EXISTS "Barbers" ( "id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT )'
  seed_db(db, ['Jessie Pinkman', 'Walter White', 'Gus Fring', 'Mike Ehrmantraut'])
  db.close
end

get '/' do
  erb :index
end

# авторизация
get '/login' do
  erb :login
end

post '/login' do
  @login    = params[:login]
  @password = params[:password]

  if @login=='admin' && @password=='secret'
    erb :admin
  else
    @dinaed='Access is denied'
    erb :login
  end
end

get '/admin' do
  erb :admin
end

# зона записи к парикмахеру
get '/visit' do
  erb :visit
end

post '/visit' do
  @user_name = params[:user_name]
	@phone = params[:phone]
	@date_time = params[:date_time]
  @barber = params[:barber]
	@color = params[:color]

	hh = { user_name: 'Введите имя', phone: 'Введите телефон', date_time: 'Введите дату и время' }
	@error = hh.select{|key,_| params[key]==''}.values.join(", ")

  return erb :visit if @error!=''

  db = get_db()
  db.execute 'INSERT INTO Users ( username, phone, datestamp, barber, color ) VALUES (?, ?, ?, ?, ?)', [@user_name, @phone, @date_time, @barber, @color]
  db.close

  @message = "Dear #{@user_name}, we'll be waiting for you at #{@date_time}"
  erb :visit
end

get '/showusers' do
	db = get_db()
	@results = db.execute 'SELECT * FROM Users ORDER BY id DESC'
	db.close
	erb :showusers
end

# зона отзывов и обратной связи
get '/contacts' do
	erb :contacts
end

post '/contacts' do
	@email = params[:email]
	@user_message = params[:user_message]

	hh = { email: 'Введите почту', user_message: 'Введите сообщение' }
	@error = hh.select{|k,_| params[k]==''}.values.join(', ')

	if @error == ''
		@message = "Сообщение принято, ответ будет прислан на вашу почту по адресу #{@email}"
	  Pony.mail(
		  {
		    :subject => 'Ваше сообщение принято',
		    :body => 'Ваше сообщение принято',
		    :to => @email,
		    :from => 'gigantkroker@gmail.com',

		    :via => :smtp,
		    :via_options => {
		      :address => 'smtp.gmail.com',
		      :port => '587',
		      :user_name => 'gigantkroker@gmail.com',
		      :password => 'lokflkbvmodiyvgy',
		      :authentication => :plain,
		      :domain => 'gmail.com'
		    }
		  }
		)
	end
	erb :contacts
end