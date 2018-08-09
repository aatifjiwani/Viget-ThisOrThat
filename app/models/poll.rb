class Poll < ApplicationRecord
  after_destroy_commit :delete_images

  belongs_to :user
  attr_accessor :expire_days
  attr_accessor :expire_hours
  attr_accessor :expire_mins
  attr_accessor :expire

  include ActionView::Helpers::DateHelper

  #Validationd
  validates :user, presence: true
  validates :title, presence: true, length: {in: 10..30}
  validates :option_a, presence: true, length: {in: 1..25}
  validates :option_b, presence: true, length: {in: 1..25}
  validate :both_image_options
  validate :expiry_time_not_zero

  has_many :comments
  has_many :votes
  has_many :follows
  has_many :visitor_votes

  has_one_attached :option_a_img
  has_one_attached :option_b_img

  scope :recent, -> { all.order(created_at: :desc) }
  scope :is_expired, -> { where("expiry_time < ? AND expired = false", DateTime.now) }

  scope :popular, -> {left_outer_joins(:votes).left_outer_joins(:visitor_votes).where(expired: false).group("polls.id").select("polls.*, (COUNT(votes.option)+COUNT(visitor_votes.option)) AS votes_count").order("votes_count DESC")}

  def expire=(input)
    @days = input[:days].to_i
    @hours = input[:hours].to_i
    @mins = input[:mins].to_i

    self.expiry_time = Time.now + @days.day + @hours.hour + @mins.minutes
  end

  def expiry_time_not_zero
    if time_left == "Less than a minute"
      errors.add(:base, "Cannot set expiry time to now")
    end
  end

  def owned_by?(user)
    self.user == user
  end

  def delete_images
    option_a_img.purge if option_a_img.attached?
    option_b_img.purge if option_b_img.attached?
  end

  def comment_count
    comments.count
  end

  def vote_count
    votes.count + visitor_votes.count
  end

  def both_image_options
    if (option_a_img.attached? and option_a_url.present?) or (option_b_img.attached? and option_b_url.present?)
      errors.add(:base, "Cannot have both a file attached and an image link. Please choose one option")
    end
  end

  def parent_is?(child)
    self.user.id == child.id
  end

  def total_votes(option)
    votes.where(option: option).count + visitor_votes.where(option: option).count
  end

  def fraction_of_votes(option)
    (total_votes(option).to_f / vote_count.to_f).round(3)
  end

  def get_option_a_img
    @image_a ||= option_a_img.attached? ? get_url(option_a_img) : option_a_url
  end

  def get_option_b_img
    @image_b ||= option_b_img.attached? ? get_url(option_b_img) : option_b_url
  end

  def get_url(image)
    @url = Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
  end

  def time_left
    (distance_of_time_in_words(DateTime.now, expiry_time).capitalize).gsub("About ", "")
  end

  def has_visitor_voted?(ip)
    get_visitor_vote(ip).present?
  end

  def get_visitor_vote(ip)
    visitor_votes.find_by(ip_address: ip)
  end

  def as_json(opts={})
    super.merge(
      time: self.time_left,
      option_a_img: self.option_a_img.attached? ? make_image_url(self.option_a_img) : '',
      option_b_img: self.option_b_img.attached? ? make_image_url(self.option_b_img) : '',
      username: self.user.username,
      comment_count: self.comments.count,
      is_user_following: !opts["user"].nil? ? opts["user"].is_following?(self.id) : false,
      has_user_voted: !opts["user"].nil? ? opts["user"].has_voted?(self.id) : false,
      has_visitor_voted: !opts["ip"].nil? ? self.has_visitor_voted?(opts["ip"]) : false
    )
  end

  def make_image_url(image)
    Rails.application.routes.url_helpers.rails_blob_url(image, host: Rails.application.config.action_controller.default_url_options[:host])
  end
end
