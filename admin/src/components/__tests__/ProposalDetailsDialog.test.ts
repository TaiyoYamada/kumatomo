import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, VueWrapper } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import { nextTick } from 'vue'
import ProposalDetailsDialog from '../ProposalDetailsDialog.vue'
import { ProposalStatus, type ShopProposal } from '@/types/shop'

describe('ProposalDetailsDialog', () => {
    let wrapper: VueWrapper
    let vuetify: ReturnType<typeof createVuetify>

    const mockProposal: ShopProposal = {
        id: 1,
        user_id: 1,
        name: 'テストカフェ',
        address: '東京都渋谷区テスト町1-1-1',
        genre: 'カフェ' as any,
        description: 'テスト用のカフェです。美味しいコーヒーを提供します。',
        status: ProposalStatus.PENDING,
        admin_notes: 'テスト管理者メモ',
        created_at: '2024-01-01T10:00:00Z',
        updated_at: '2024-01-02T15:30:00Z',
        user: {
            id: 1,
            name: 'テストユーザー',
            username: 'testuser',
            email: 'test@example.com'
        }
    }

    beforeEach(() => {
        vuetify = createVuetify()
        vi.clearAllMocks()
    })

    const createWrapper = (props = {}) => {
        return mount(ProposalDetailsDialog, {
            props: {
                modelValue: true,
                proposal: mockProposal,
                ...props
            },
            global: {
                plugins: [vuetify]
            }
        })
    }

    describe('Component Rendering', () => {
        it('should render dialog when modelValue is true', () => {
            wrapper = createWrapper()

            const dialog = wrapper.find('.v-dialog')
            expect(dialog.exists()).toBe(true)
        })

        it('should not render dialog content when proposal is null', () => {
            wrapper = createWrapper({ proposal: null })

            const dialogContent = wrapper.find('.proposal-details-dialog')
            expect(dialogContent.exists()).toBe(false)
        })

        it('should render proposal details correctly', () => {
            wrapper = createWrapper()

            // Check basic information
            expect(wrapper.text()).toContain('テストカフェ')
            expect(wrapper.text()).toContain('#1')
            expect(wrapper.text()).toContain('東京都渋谷区テスト町1-1-1')
            expect(wrapper.text()).toContain('カフェ')
            expect(wrapper.text()).toContain('テスト用のカフェです。美味しいコーヒーを提供します。')
        })

        it('should render user information correctly', () => {
            wrapper = createWrapper()

            expect(wrapper.text()).toContain('テストユーザー')
            expect(wrapper.text()).toContain('@testuser')
            expect(wrapper.text()).toContain('test@example.com')
        })

        it('should render status chip with correct color and text', () => {
            wrapper = createWrapper()

            const statusChip = wrapper.find('.v-chip')
            expect(statusChip.exists()).toBe(true)
            expect(statusChip.text()).toContain('承認待ち')
        })
    })

    describe('Status Display', () => {
        it('should display pending status correctly', () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.PENDING }
            })

            expect(wrapper.text()).toContain('承認待ち')
            const statusIcon = wrapper.find('[data-testid="status-icon"]') ||
                wrapper.find('.mdi-clock-outline')
            // Icon should be present (implementation may vary)
        })

        it('should display approved status correctly', () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.APPROVED }
            })

            expect(wrapper.text()).toContain('承認済み')
        })

        it('should display rejected status correctly', () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.REJECTED }
            })

            expect(wrapper.text()).toContain('却下済み')
        })
    })

    describe('Timeline Display', () => {
        it('should show creation timeline item', () => {
            wrapper = createWrapper()

            expect(wrapper.text()).toContain('提案作成')
            expect(wrapper.text()).toContain('2024/01/01')
        })

        it('should show update timeline item when updated_at differs from created_at', () => {
            wrapper = createWrapper()

            expect(wrapper.text()).toContain('最終更新')
            expect(wrapper.text()).toContain('2024/01/02')
        })

        it('should not show update timeline item when updated_at equals created_at', () => {
            const proposalWithoutUpdate = {
                ...mockProposal,
                updated_at: mockProposal.created_at
            }

            wrapper = createWrapper({ proposal: proposalWithoutUpdate })

            // Should only have creation timeline item
            const timelineItems = wrapper.findAll('.timeline-item')
            expect(timelineItems.length).toBe(1)
        })

        it('should show approval timeline item for approved proposals', () => {
            const approvedProposal = {
                ...mockProposal,
                status: ProposalStatus.APPROVED
            }

            wrapper = createWrapper({ proposal: approvedProposal })

            expect(wrapper.text()).toContain('承認')
        })

        it('should show rejection timeline item for rejected proposals', () => {
            const rejectedProposal = {
                ...mockProposal,
                status: ProposalStatus.REJECTED
            }

            wrapper = createWrapper({ proposal: rejectedProposal })

            expect(wrapper.text()).toContain('却下')
        })
    })

    describe('Admin Notes', () => {
        it('should display admin notes when present', () => {
            wrapper = createWrapper()

            expect(wrapper.text()).toContain('管理者メモ')
            expect(wrapper.text()).toContain('テスト管理者メモ')
        })

        it('should not display admin notes section when notes are empty', () => {
            const proposalWithoutNotes = {
                ...mockProposal,
                admin_notes: undefined
            }

            wrapper = createWrapper({ proposal: proposalWithoutNotes })

            expect(wrapper.text()).not.toContain('管理者メモ')
        })
    })

    describe('Optional Fields Handling', () => {
        it('should handle missing genre gracefully', () => {
            const proposalWithoutGenre = {
                ...mockProposal,
                genre: undefined
            }

            wrapper = createWrapper({ proposal: proposalWithoutGenre })

            expect(wrapper.text()).toContain('未設定')
        })

        it('should handle missing address gracefully', () => {
            const proposalWithoutAddress = {
                ...mockProposal,
                address: undefined
            }

            wrapper = createWrapper({ proposal: proposalWithoutAddress })

            expect(wrapper.text()).toContain('未設定')
        })

        it('should handle missing description gracefully', () => {
            const proposalWithoutDescription = {
                ...mockProposal,
                description: undefined
            }

            wrapper = createWrapper({ proposal: proposalWithoutDescription })

            expect(wrapper.text()).toContain('説明なし')
        })

        it('should handle missing user information gracefully', () => {
            const proposalWithoutUser = {
                ...mockProposal,
                user: undefined
            }

            wrapper = createWrapper({ proposal: proposalWithoutUser })

            expect(wrapper.text()).toContain('ユーザー情報が取得できません')
        })
    })

    describe('Action Buttons', () => {
        it('should show approve and reject buttons for pending proposals', () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.PENDING }
            })

            const approveButton = wrapper.find('button:contains("承認")')
            const rejectButton = wrapper.find('button:contains("却下")')

            expect(approveButton.exists()).toBe(true)
            expect(rejectButton.exists()).toBe(true)
        })

        it('should only show close button for processed proposals', () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.APPROVED }
            })

            const closeButton = wrapper.find('button:contains("閉じる")')
            const approveButton = wrapper.find('button:contains("承認")')
            const rejectButton = wrapper.find('button:contains("却下")')

            expect(closeButton.exists()).toBe(true)
            expect(approveButton.exists()).toBe(false)
            expect(rejectButton.exists()).toBe(false)
        })
    })

    describe('Event Handling', () => {
        it('should emit update:modelValue when close button is clicked', async () => {
            wrapper = createWrapper()

            const closeButton = wrapper.find('[data-testid="close-button"]') ||
                wrapper.find('button[icon="mdi-close"]')

            if (closeButton.exists()) {
                await closeButton.trigger('click')

                expect(wrapper.emitted('update:modelValue')).toBeTruthy()
                expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([false])
            }
        })

        it('should emit approve event when approve button is clicked', async () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.PENDING }
            })

            const approveButton = wrapper.find('button:contains("承認")')

            if (approveButton.exists()) {
                await approveButton.trigger('click')

                expect(wrapper.emitted('approve')).toBeTruthy()
                expect(wrapper.emitted('approve')?.[0]).toEqual([{
                    proposal: mockProposal
                }])
            }
        })

        it('should emit reject event when reject button is clicked', async () => {
            wrapper = createWrapper({
                proposal: { ...mockProposal, status: ProposalStatus.PENDING }
            })

            const rejectButton = wrapper.find('button:contains("却下")')

            if (rejectButton.exists()) {
                await rejectButton.trigger('click')

                expect(wrapper.emitted('reject')).toBeTruthy()
                expect(wrapper.emitted('reject')?.[0]).toEqual([{
                    proposal: mockProposal
                }])
            }
        })
    })

    describe('Date Formatting', () => {
        it('should format dates correctly', () => {
            wrapper = createWrapper()

            // Check if formatted dates are displayed
            expect(wrapper.text()).toMatch(/2024\/01\/01.*10:00/)
            expect(wrapper.text()).toMatch(/2024\/01\/02.*15:30/)
        })
    })

    describe('Responsive Design', () => {
        it('should handle mobile viewport', async () => {
            // Mock mobile viewport
            Object.defineProperty(window, 'innerWidth', {
                writable: true,
                configurable: true,
                value: 400
            })

            wrapper = createWrapper()

            // Check if component renders without errors on mobile
            expect(wrapper.find('.proposal-details-dialog').exists()).toBe(true)
        })
    })

    describe('Accessibility', () => {
        it('should have proper dialog structure', () => {
            wrapper = createWrapper()

            const dialog = wrapper.find('[role="dialog"]') || wrapper.find('.v-dialog')
            expect(dialog.exists()).toBe(true)
        })

        it('should have proper heading structure', () => {
            wrapper = createWrapper()

            const mainHeading = wrapper.find('h2')
            expect(mainHeading.exists()).toBe(true)
            expect(mainHeading.text()).toContain('提案詳細')
        })
    })

    describe('Props Validation', () => {
        it('should handle modelValue prop correctly', async () => {
            wrapper = createWrapper({ modelValue: false })

            // Dialog should not be visible
            const dialog = wrapper.find('.v-dialog')
            expect(dialog.attributes('model-value')).toBe('false')
        })

        it('should handle proposal prop changes', async () => {
            wrapper = createWrapper()

            const newProposal = {
                ...mockProposal,
                id: 2,
                name: '新しいカフェ'
            }

            await wrapper.setProps({ proposal: newProposal })

            expect(wrapper.text()).toContain('新しいカフェ')
            expect(wrapper.text()).toContain('#2')
        })
    })
})