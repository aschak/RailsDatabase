require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true

  end

end

class User

  def self.all
    all_users = QuestionsDatabase.instance.execute('SELECT * FROM users')
    all_users.map{|user| User.new(user)}
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = #{id}")
    User.new(user.first)
  end

  def self.find_by_name(first, last)
    user = QuestionsDatabase.instance.execute(<<-SQL, first, last)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    User.new(user.first)

  end

  def average_karma
    num_questions = QuestionsDatabase.instance.get_first_row(<<-SQL)
      SELECT
        CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(DISTINCT questions.id)
      FROM
        questions
      LEFT OUTER JOIN
        question_likes ON questions.id = question_likes.question_id
      WHERE
        questions.user_id = #{@id}
    SQL

    num_questions.values.first
  end


  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save
    if id
      QuestionsDatabase.instance.execute(<<-SQL)
        UPDATE
          users
        SET
          fname = '#{@fname}', lname = '#{@lname}'
        WHERE
          users.id = #{@id}
      SQL
    else
      self.create
    end
  end

  def create
    raise 'already saved' if id

    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

end


class Question

  def self.all
    questions = QuestionsDatabase.instance.execute('SELECT * FROM questions')
    questions.map {|question| Question.new(question)}
  end


  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = #{id}")
    Question.new(question.first)
  end

  def self.find_by_author_id(id)
    questions = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE user_id = #{id}")
    questions.map {|question| Question.new(question)}
  end

  def self.most_followed(n = 1)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n = 1)
    QuestionLike.most_liked_questions(n)
  end

  attr_accessor :id, :title, :body, :user_id

  def initialize(options)
    @id, @title, @body, @user_id =
      options.values_at('id', 'title', 'body', 'user_id')
  end


  def create
    raise 'already saved' if id

    QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id)
      INSERT INTO
        questions(title, body, user_id)
      VALUES
        (?, ?, ? )
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end


end


class QuestionFollow

  def self.all
    question_f = QuestionsDatabase.instance.execute('SELECT * FROM question_follows')
    question_f.map {|question_f| QuestionFollow.new(question_f)}
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        fname, lname, users.id AS id
      FROM
        users
      JOIN
        question_follows ON users.id = question_follows.user_id
      WHERE
        question_follows.question_id = #{question_id}
    SQL

    users.map{|user| User.new(user)}
  end


  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        title, body, question_follows.user_id AS user_id, questions.id AS id
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      WHERE
        question_follows.user_id = #{user_id}
    SQL

    questions.map {|question| Question.new(question)}

  end

  def self.most_followed_questions(n = 1)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        title, body, questions.user_id AS user_id, question_id AS id, COUNT(question_follows.question_id) AS num_follows
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      GROUP BY
       question_follows.question_id
      ORDER BY
        num_follows DESC
      LIMIT #{n}
    SQL

    questions.map {|question| Question.new(question)}
  end

  def self.find_by_id(id)
    question_f = QuestionsDatabase.instance.execute("SELECT * FROM question_follows WHERE id = #{id}")
    QuestionFollow.new(question_f.first)
  end

  attr_accessor :id, :question_id, :user_id

  def initialize(options)
    @id, @question_id, @user_id =
      options.values_at('id', 'question_id', 'user_id')
  end


  def create
    raise 'already saved' if id

    QuestionsDatabase.instance.execute(<<-SQL, question_id, user_id)
      INSERT INTO
        question_follows(question_id, user_id)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

end

class Reply

  def self.all
    reply = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    reply.map {|reply| Reply.new(reply)}
  end


  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{id}")
    Reply.new(reply.first)
  end

  def self.find_by_user_id(id)
    replies = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE user_id = #{id}")
    replies.map {|reply| Reply.new(reply)}
  end

  def self.find_by_question_id(id)
    replies = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{id}")
    replies.map {|reply| Reply.new(reply)}
  end


  attr_accessor :id, :question_id, :parent_reply_id, :user_id, :body

  def initialize(options)
    @id, @question_id, @parent_reply_id, @user_id, @body =
      options.values_at('id', 'question_id', 'parent_reply_id', 'user_id', 'body')
  end


  def create
    raise 'already saved' if id

    QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_reply_id, user_id, body)
      INSERT INTO
        replies(question_id, parent_reply_id, user_id, body)
      VALUES
        (?, ?, ?, ? )
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    if @parent_reply_id
      return Reply.find_by_id(@parent_reply_id)
    end

    nil
  end

  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL)
        SELECT
          *
        FROM
          replies
        WHERE
          parent_reply_id = #{@id}
    SQL
    replies.map {|reply| Reply.new(reply)}
  end

end

class QuestionLike

  def self.all
    question_l = QuestionsDatabase.instance.execute('SELECT * FROM question_likes')
    question_l.map {|question_l| QuestionLike.new(question_l)}
  end


  def self.find_by_id(id)
    question_l = QuestionsDatabase.instance.execute("SELECT * FROM question_likes WHERE id = #{id}")
    QuestionLike.new(question_l.first)
  end

  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        fname, lname, users.id AS id
      FROM
        question_likes
      JOIN
        users ON question_likes.user_id = users.id
      WHERE
        question_id = #{question_id}
    SQL
    users.map {|user| User.new(user)}
  end


  def self.num_likes_for_question_id(id)
    count = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        COUNT(user_id) AS count
      FROM
        question_likes
      WHERE
        question_id = #{id}
    SQL
    count.first["count"]
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        title, body, questions.id AS id, questions.user_id AS user_id
      FROM
        question_likes
      JOIN
        questions ON questions.id = question_likes.question_id
      WHERE
        question_likes.user_id = #{user_id}
    SQL
    questions.map {|question| Question.new(question)}
  end

  def self.most_liked_questions(n = 1)
    questions = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        question_id AS id, COUNT(question_id) AS total_likes
      FROM
        question_likes
      GROUP BY
        question_id
      ORDER BY
        total_likes DESC
      LIMIT #{n}

    SQL

    questions.map {|question| Question.find_by_id(question['id'])}

  end

  attr_accessor :id, :question_id, :user_id

  def initialize(options)
    @id, @question_id, @user_id =
      options.values_at('id', 'question_id', 'user_id')
  end


  def create
    raise 'already saved' if id

    QuestionsDatabase.instance.execute(<<-SQL, question_id, user_id)
      INSERT INTO
        question_likes(question_id, user_id)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

end
