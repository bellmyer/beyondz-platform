# kind == 'user_confirm' means the user just checks it off (rendered as checkbox or plain "Done" button)
# kind == 'file'         means upload file
# kind == 'text'         means it expects text (rendered as textarea)
class TaskDefinition < ActiveRecord::Base

  belongs_to :assignment_definition
  has_many :tasks, dependent: :destroy

  enum kind: { file: 0, user_confirm: 1, text: 2, quiz: 3 }
  enum file_type: { document: 0, image: 1, video: 2, audio: 3 }


  default_scope { order('position ASC') }
  scope :required, -> { where(required: true) }
  scope :not_required, -> { where(required: false) }
  scope :require_approval, -> { where(requires_approval: true) }
  scope :do_not_require_approval, -> { where(requires_approval: false) }

end